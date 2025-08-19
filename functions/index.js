const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onCall } = require('firebase-functions/v2/https');
const { HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

// Initialiser Firebase Admin
admin.initializeApp();

// Services
const firestore = admin.firestore();
const messaging = admin.messaging();

// Helper functions pour les notifications riches
async function renderTemplate(templateId, variables) {
  try {
    const templateDoc = await firestore.collection('notificationTemplates').doc(templateId).get();
    if (!templateDoc.exists) {
      throw new Error('Template non trouvé');
    }
    
    const template = templateDoc.data();
    let title = template.title || '';
    let body = template.body || '';
    
    // Remplacer les variables dans le format {{variable}}
    Object.keys(variables).forEach(key => {
      const regex = new RegExp(`{{${key}}}`, 'g');
      title = title.replace(regex, variables[key] || '');
      body = body.replace(regex, variables[key] || '');
    });
    
    return {
      title,
      body,
      actions: template.actions || [],
      imageUrl: template.imageUrl
    };
  } catch (error) {
    console.error('Erreur lors du rendu du template:', error);
    throw error;
  }
}

async function getSegmentUsers(segmentId) {
  try {
    const segmentDoc = await firestore.collection('userSegments').doc(segmentId).get();
    if (!segmentDoc.exists) {
      throw new Error('Segment non trouvé');
    }
    
    const segment = segmentDoc.data();
    const criteria = segment.criteria || {};
    
    let query = firestore.collection('users');
    
    // Appliquer les critères dynamiques
    if (criteria.role) {
      query = query.where('role', '==', criteria.role);
    }
    if (criteria.department) {
      query = query.where('department', '==', criteria.department);
    }
    if (criteria.location) {
      query = query.where('location', '==', criteria.location);
    }
    if (criteria.isActive !== undefined) {
      query = query.where('isActive', '==', criteria.isActive);
    }
    
    const usersSnapshot = await query.get();
    return usersSnapshot.docs.map(doc => doc.id);
  } catch (error) {
    console.error('Erreur lors de la récupération des utilisateurs du segment:', error);
    throw error;
  }
}

async function getUserTokens(userIds) {
  try {
    const tokens = [];
    const batchSize = 10; // Firestore limite les requêtes 'in' à 10 éléments
    
    for (let i = 0; i < userIds.length; i += batchSize) {
      const batch = userIds.slice(i, i + batchSize);
      const usersSnapshot = await firestore.collection('users')
        .where(admin.firestore.FieldPath.documentId(), 'in', batch)
        .get();
      
      usersSnapshot.docs.forEach(doc => {
        const userData = doc.data();
        if (userData.fcmToken) {
          tokens.push(userData.fcmToken);
        }
      });
    }
    
    return tokens;
  } catch (error) {
    console.error('Erreur lors de la récupération des tokens:', error);
    return [];
  }
}

async function trackNotificationActions(notificationId, userIds, action, priority) {
  try {
    const batch = firestore.batch();
    const timestamp = admin.firestore.FieldValue.serverTimestamp();
    
    // Mettre à jour les analytics globales
    const analyticsRef = firestore.collection('notificationAnalytics').doc(notificationId);
    batch.set(analyticsRef, {
      notificationId,
      [`${action}Count`]: admin.firestore.FieldValue.increment(userIds.length),
      [`${action}At`]: timestamp,
      priority,
      lastUpdated: timestamp
    }, { merge: true });
    
    // Enregistrer les actions individuelles
    userIds.forEach(userId => {
      const actionRef = firestore.collection('notificationActions').doc();
      batch.set(actionRef, {
        notificationId,
        userId,
        action,
        timestamp,
        platform: 'mobile', // Pourrait être déterminé dynamiquement
        priority
      });
    });
    
    await batch.commit();
  } catch (error) {
    console.error('Erreur lors du tracking des actions:', error);
  }
}

async function cleanupInvalidTokensFromBatch(batchResult, tokens) {
  try {
    const invalidTokens = [];
    
    batchResult.responses.forEach((response, index) => {
      if (!response.success && response.error) {
        const errorCode = response.error.code;
        if (errorCode === 'messaging/invalid-registration-token' || 
            errorCode === 'messaging/registration-token-not-registered') {
          invalidTokens.push(tokens[index]);
        }
      }
    });
    
    if (invalidTokens.length > 0) {
      // Supprimer les tokens invalides de la base de données
      const batch = firestore.batch();
      
      for (const token of invalidTokens) {
        const usersSnapshot = await firestore.collection('users')
          .where('fcmToken', '==', token)
          .get();
        
        usersSnapshot.docs.forEach(doc => {
          batch.update(doc.ref, {
            fcmToken: admin.firestore.FieldValue.delete(),
            fcmTokenUpdatedAt: admin.firestore.FieldValue.delete()
          });
        });
      }
      
      await batch.commit();
      console.log(`${invalidTokens.length} tokens invalides supprimés`);
    }
  } catch (error) {
    console.error('Erreur lors du nettoyage des tokens invalides:', error);
  }
}

function getPriorityMapping(priority) {
  switch (priority) {
    case 'high': return 'high';
    case 'normal': return 'normal';
    case 'low': return 'normal';
    default: return 'normal';
  }
}

function getWebPushUrgency(priority) {
  switch (priority) {
    case 'high': return 'high';
    case 'normal': return 'normal';
    case 'low': return 'low';
    default: return 'normal';
  }
}

/**
 * Fonction avancée pour envoyer des notifications riches
 * Supporte les images, actions, segmentation et analytics
 */
exports.sendRichNotification = onCall({
  region: 'us-central1',
}, async (request) => {
  try {
    const { 
      title, 
      body, 
      imageUrl, 
      actions = [], 
      data = {}, 
      priority = 'normal',
      segmentId,
      templateId,
      templateVariables = {},
      trackAnalytics = true
    } = request.data;

    // Validation de l'authentification
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Utilisateur non authentifié');
    }

    const senderId = request.auth.uid;
    
    // Résoudre le template si fourni
    let finalTitle = title;
    let finalBody = body;
    let finalActions = actions;
    let finalImageUrl = imageUrl;

    if (templateId) {
      const template = await renderTemplate(templateId, templateVariables);
      finalTitle = template.title || title;
      finalBody = template.body || body;
      finalActions = template.actions || actions;
      finalImageUrl = template.imageUrl || imageUrl;
    }

    // Résoudre les destinataires
    let recipients = [];
    if (segmentId) {
      recipients = await getSegmentUsers(segmentId);
    } else {
      // Par défaut : tous les utilisateurs actifs
      const usersSnapshot = await firestore.collection('users')
        .where('isActive', '==', true)
        .get();
      recipients = usersSnapshot.docs.map(doc => doc.id);
    }

    if (recipients.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Aucun destinataire trouvé');
    }

    // Créer l'objet notification riche
    const notification = {
      id: admin.firestore().collection('notifications').doc().id,
      title: finalTitle,
      body: finalBody,
      imageUrl: finalImageUrl,
      actions: finalActions,
      data: {
        ...data,
        notificationId: notification.id,
        priority: priority,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      },
      recipients: recipients,
      senderId: senderId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      type: 'rich',
      priority: priority
    };

    // Sauvegarder la notification
    await firestore.collection('notifications').doc(notification.id).set(notification);

    // Préparer le message FCM enrichi
    const fcmMessage = {
      notification: {
        title: finalTitle,
        body: finalBody,
        ...(finalImageUrl && { imageUrl: finalImageUrl })
      },
      data: {
        notificationId: notification.id,
        type: 'rich',
        priority: priority,
        actions: JSON.stringify(finalActions),
        ...data
      },
      android: {
        priority: getPriorityMapping(priority),
        notification: {
          channelId: 'church_notifications',
          priority: getPriorityMapping(priority),
          ...(finalImageUrl && { imageUrl: finalImageUrl }),
          actions: finalActions.map(action => ({
            action: action.id,
            title: action.title,
            icon: action.icon || 'ic_notification_action'
          }))
        }
      },
      apns: {
        payload: {
          aps: {
            category: 'RICH_NOTIFICATION',
            'mutable-content': 1,
            ...(finalImageUrl && { 'media-url': finalImageUrl })
          }
        }
      },
      webpush: {
        headers: {
          Urgency: getWebPushUrgency(priority)
        },
        notification: {
          title: finalTitle,
          body: finalBody,
          ...(finalImageUrl && { image: finalImageUrl }),
          actions: finalActions.map(action => ({
            action: action.id,
            title: action.title,
            icon: action.icon || '/icons/action-icon.png'
          })),
          badge: '/icons/badge-icon.png',
          tag: notification.id
        }
      }
    };

    // Envoyer aux destinataires par batches
    const batchSize = 500;
    const results = [];

    for (let i = 0; i < recipients.length; i += batchSize) {
      const batch = recipients.slice(i, i + batchSize);
      const tokens = await getUserTokens(batch);
      
      if (tokens.length > 0) {
        try {
          const batchResult = await messaging.sendEachForMulticast({
            ...fcmMessage,
            tokens: tokens
          });
          
          results.push(batchResult);
          
          // Analytics: tracking des envois
          if (trackAnalytics) {
            await trackNotificationActions(notification.id, batch, 'sent', priority);
          }

          // Nettoyer les tokens invalides
          await cleanupInvalidTokensFromBatch(batchResult, tokens);
          
        } catch (error) {
          console.error('Erreur envoi batch:', error);
          
          // Analytics: tracking des échecs
          if (trackAnalytics) {
            await trackNotificationActions(notification.id, batch, 'failed', priority);
          }
        }
      }
    }

    // Calculer les statistiques d'envoi
    const totalSuccess = results.reduce((acc, result) => acc + result.successCount, 0);
    const totalFailure = results.reduce((acc, result) => acc + result.failureCount, 0);

    // Mettre à jour les statistiques de la notification
    await firestore.collection('notificationStats').doc(notification.id).set({
      notificationId: notification.id,
      totalSent: recipients.length,
      totalDelivered: totalSuccess,
      totalFailed: totalFailure,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      priority: priority,
      type: 'rich'
    });

    return {
      success: true,
      notificationId: notification.id,
      totalRecipients: recipients.length,
      successCount: totalSuccess,
      failureCount: totalFailure,
      results: results
    };

  } catch (error) {
    console.error('Erreur dans sendRichNotification:', error);
    throw new HttpsError('internal', 'Erreur lors de l\'envoi: ' + error.message);
  }
});

/**
 * Fonction pour envoyer des notifications push
 * Appelée depuis l'application Flutter
 */
exports.sendPushNotification = onCall({
  region: 'us-central1',
}, async (request) => {
  // Vérifier l'authentification
  if (!request.auth) {
    throw new Error('Utilisateur non authentifié');
  }

  const { token, title, body, data: notificationData } = request.data;

  if (!token || !title || !body) {
    throw new Error('Paramètres manquants');
  }

  try {
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: notificationData || {},
      token: token,
      android: {
        notification: {
          sound: 'default',
          priority: 'high',
          channelId: 'high_importance_channel',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log('Notification envoyée avec succès:', response);
    
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Erreur lors de l\'envoi de la notification:', error);
    throw new Error('Erreur lors de l\'envoi de la notification: ' + error.message);
  }
});

/**
 * Fonction pour envoyer des notifications à plusieurs utilisateurs
 */
exports.sendMulticastNotification = onCall({
  region: 'us-central1',
}, async (request) => {
  if (!request.auth) {
    throw new Error('Utilisateur non authentifié');
  }

  const { tokens, title, body, data: notificationData } = request.data;

  if (!tokens || !Array.isArray(tokens) || tokens.length === 0 || !title || !body) {
    throw new Error('Paramètres manquants ou invalides');
  }

  try {
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: notificationData || {},
      tokens: tokens,
      android: {
        notification: {
          sound: 'default',
          priority: 'high',
          channelId: 'high_importance_channel',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    console.log('Notifications multicast envoyées:', response);

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
      responses: response.responses
    };
  } catch (error) {
    console.error('Erreur lors de l\'envoi des notifications multicast:', error);
    throw new Error('Erreur lors de l\'envoi des notifications: ' + error.message);
  }
});

/**
 * Fonction pour tracker les actions des notifications (ouverture, clic, etc.)
 */
exports.trackNotificationAction = onCall({
  region: 'us-central1',
}, async (request) => {
  try {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Utilisateur non authentifié');
    }

    const { notificationId, action, platform = 'mobile' } = request.data;
    const userId = request.auth.uid;

    if (!notificationId || !action) {
      throw new HttpsError('invalid-argument', 'Paramètres manquants');
    }

    // Enregistrer l'action
    await firestore.collection('notificationActions').add({
      notificationId,
      userId,
      action, // 'opened', 'clicked', 'dismissed'
      platform,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    // Mettre à jour les statistiques
    const analyticsRef = firestore.collection('notificationAnalytics').doc(notificationId);
    await analyticsRef.set({
      [`${action}Count`]: admin.firestore.FieldValue.increment(1),
      [`${action}At`]: admin.firestore.FieldValue.serverTimestamp(),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    return { success: true };
  } catch (error) {
    console.error('Erreur lors du tracking:', error);
    throw new HttpsError('internal', 'Erreur lors du tracking: ' + error.message);
  }
});

/**
 * Fonction pour créer un nouveau segment d'utilisateurs
 */
exports.createUserSegment = onCall({
  region: 'us-central1',
}, async (request) => {
  try {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Utilisateur non authentifié');
    }

    const { name, description, criteria, type = 'dynamic' } = request.data;

    if (!name || !criteria) {
      throw new HttpsError('invalid-argument', 'Nom et critères requis');
    }

    // Créer le segment
    const segmentRef = await firestore.collection('userSegments').add({
      name,
      description: description || '',
      criteria,
      type, // 'dynamic' ou 'static'
      createdBy: request.auth.uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true
    });

    // Calculer le nombre d'utilisateurs dans le segment
    const userCount = await getSegmentUserCount(criteria);

    // Mettre à jour avec le nombre d'utilisateurs
    await segmentRef.update({
      userCount,
      lastCalculated: admin.firestore.FieldValue.serverTimestamp()
    });

    return {
      success: true,
      segmentId: segmentRef.id,
      userCount
    };
  } catch (error) {
    console.error('Erreur lors de la création du segment:', error);
    throw new HttpsError('internal', 'Erreur lors de la création: ' + error.message);
  }
});

/**
 * Fonction pour récupérer les analytics d'une notification
 */
exports.getNotificationAnalytics = onCall({
  region: 'us-central1',
}, async (request) => {
  try {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Utilisateur non authentifié');
    }

    const { notificationId, startDate, endDate } = request.data;

    if (!notificationId) {
      throw new HttpsError('invalid-argument', 'ID de notification requis');
    }

    // Récupérer les analytics de base
    const analyticsDoc = await firestore.collection('notificationAnalytics').doc(notificationId).get();
    const analytics = analyticsDoc.exists ? analyticsDoc.data() : {};

    // Récupérer les actions détaillées
    let actionsQuery = firestore.collection('notificationActions')
      .where('notificationId', '==', notificationId);

    if (startDate) {
      actionsQuery = actionsQuery.where('timestamp', '>=', new Date(startDate));
    }
    if (endDate) {
      actionsQuery = actionsQuery.where('timestamp', '<=', new Date(endDate));
    }

    const actionsSnapshot = await actionsQuery.get();
    const actions = actionsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      timestamp: doc.data().timestamp?.toDate()
    }));

    // Calculer les statistiques
    const stats = {
      totalSent: analytics.sentCount || 0,
      totalOpened: analytics.openedCount || 0,
      totalClicked: analytics.clickedCount || 0,
      totalDismissed: analytics.dismissedCount || 0,
      openRate: analytics.sentCount ? (analytics.openedCount || 0) / analytics.sentCount : 0,
      clickRate: analytics.sentCount ? (analytics.clickedCount || 0) / analytics.sentCount : 0,
      actions: actions
    };

    return { success: true, analytics: stats };
  } catch (error) {
    console.error('Erreur lors de la récupération des analytics:', error);
    throw new HttpsError('internal', 'Erreur lors de la récupération: ' + error.message);
  }
});

async function getSegmentUserCount(criteria) {
  try {
    let query = firestore.collection('users');
    
    if (criteria.role) {
      query = query.where('role', '==', criteria.role);
    }
    if (criteria.department) {
      query = query.where('department', '==', criteria.department);
    }
    if (criteria.location) {
      query = query.where('location', '==', criteria.location);
    }
    if (criteria.isActive !== undefined) {
      query = query.where('isActive', '==', criteria.isActive);
    }
    
    const snapshot = await query.get();
    return snapshot.size;
  } catch (error) {
    console.error('Erreur lors du calcul du nombre d\'utilisateurs:', error);
    return 0;
  }
}

/**
 * Fonction déclenchée automatiquement lors de la création d'un rendez-vous
 */
exports.onAppointmentCreated = onDocumentCreated('appointments/{appointmentId}', async (event) => {
  const appointment = event.data.data();
  const appointmentId = event.params.appointmentId;

  if (!appointment) {
    console.log('Aucune donnée de rendez-vous trouvée');
    return;
  }

  try {
    // Récupérer le demandeur du rendez-vous
    if (appointment.requesterId) {
      const requesterDoc = await admin.firestore()
        .collection('people')
        .doc(appointment.requesterId)
        .get();

      if (requesterDoc.exists) {
        const requester = requesterDoc.data();
        
        // Envoyer une notification de confirmation au demandeur
        if (requester.fcmToken) {
          const message = {
            notification: {
              title: 'Rendez-vous confirmé',
              body: `Votre rendez-vous pour "${appointment.subject}" a été confirmé.`,
            },
            data: {
              type: 'appointment_confirmed',
              appointmentId: appointmentId,
            },
            token: requester.fcmToken,
          };

          await admin.messaging().send(message);
          console.log('Notification de confirmation envoyée au demandeur');
        }
      }
    }

    // Récupérer l'assigné du rendez-vous
    if (appointment.assignedTo) {
      const assigneeDoc = await admin.firestore()
        .collection('people')
        .doc(appointment.assignedTo)
        .get();

      if (assigneeDoc.exists) {
        const assignee = assigneeDoc.data();
        
        // Envoyer une notification au responsable assigné
        if (assignee.fcmToken) {
          const message = {
            notification: {
              title: 'Nouveau rendez-vous assigné',
              body: `Nouveau rendez-vous: "${appointment.subject}"`,
            },
            data: {
              type: 'appointment_assigned',
              appointmentId: appointmentId,
            },
            token: assignee.fcmToken,
          };

          await admin.messaging().send(message);
          console.log('Notification d\'assignation envoyée');
        }
      }
    }
  } catch (error) {
    console.error('Erreur lors de l\'envoi des notifications de rendez-vous:', error);
  }
});

/**
 * Fonction déclenchée lors de la mise à jour d'un rendez-vous
 */
exports.onAppointmentUpdated = onDocumentUpdated('appointments/{appointmentId}', async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();
  const appointmentId = event.params.appointmentId;

  if (!beforeData || !afterData) {
    return;
  }

  try {
    // Vérifier si le statut a changé
    if (beforeData.status !== afterData.status) {
      // Notifier le demandeur du changement de statut
      if (afterData.requesterId) {
        const requesterDoc = await admin.firestore()
          .collection('people')
          .doc(afterData.requesterId)
          .get();

        if (requesterDoc.exists) {
          const requester = requesterDoc.data();
          
          if (requester.fcmToken) {
            let title = 'Rendez-vous mis à jour';
            let body = `Le statut de votre rendez-vous a changé: ${afterData.status}`;

            if (afterData.status === 'completed') {
              title = 'Rendez-vous terminé';
              body = `Votre rendez-vous "${afterData.subject}" est terminé.`;
            } else if (afterData.status === 'cancelled') {
              title = 'Rendez-vous annulé';
              body = `Votre rendez-vous "${afterData.subject}" a été annulé.`;
            }

            const message = {
              notification: { title, body },
              data: {
                type: 'appointment_updated',
                appointmentId: appointmentId,
                newStatus: afterData.status,
              },
              token: requester.fcmToken,
            };

            await admin.messaging().send(message);
            console.log('Notification de mise à jour envoyée au demandeur');
          }
        }
      }
    }
  } catch (error) {
    console.error('Erreur lors de l\'envoi des notifications de mise à jour:', error);
  }
});

/**
 * Fonction programmée pour nettoyer les tokens inactifs
 * S'exécute tous les dimanches à 2h du matin
 */
exports.cleanupInactiveTokens = onSchedule('0 2 * * 0', async (event) => {
  console.log('Début du nettoyage des tokens inactifs');
  
  try {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 30); // 30 jours

    // Récupérer tous les utilisateurs avec des tokens anciens
    const usersSnapshot = await admin.firestore()
      .collection('people')
      .where('fcmTokenUpdatedAt', '<', cutoffDate)
      .get();

    const batch = admin.firestore().batch();
    let cleanupCount = 0;

    usersSnapshot.forEach((doc) => {
      const userData = doc.data();
      if (userData.fcmToken) {
        // Supprimer le token ancien
        batch.update(doc.ref, {
          fcmToken: admin.firestore.FieldValue.delete(),
          fcmTokenUpdatedAt: admin.firestore.FieldValue.delete(),
        });
        cleanupCount++;
      }
    });

    if (cleanupCount > 0) {
      await batch.commit();
      console.log(`${cleanupCount} tokens inactifs supprimés`);
    } else {
      console.log('Aucun token inactif trouvé');
    }
  } catch (error) {
    console.error('Erreur lors du nettoyage des tokens:', error);
  }
});

/**
 * Fonction programmée pour envoyer des rappels de rendez-vous
 * S'exécute tous les jours à 9h du matin
 */
exports.sendAppointmentReminders = onSchedule('0 9 * * *', async (event) => {
  console.log('Début de l\'envoi des rappels de rendez-vous');
  
  try {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);
    
    const dayAfterTomorrow = new Date(tomorrow);
    dayAfterTomorrow.setDate(dayAfterTomorrow.getDate() + 1);

    // Récupérer les rendez-vous de demain
    const appointmentsSnapshot = await admin.firestore()
      .collection('appointments')
      .where('scheduledDate', '>=', tomorrow)
      .where('scheduledDate', '<', dayAfterTomorrow)
      .where('status', 'in', ['scheduled', 'confirmed'])
      .get();

    const notifications = [];

    for (const doc of appointmentsSnapshot.docs) {
      const appointment = doc.data();
      
      if (appointment.requesterId) {
        const requesterDoc = await admin.firestore()
          .collection('people')
          .doc(appointment.requesterId)
          .get();

        if (requesterDoc.exists) {
          const requester = requesterDoc.data();
          
          if (requester.fcmToken) {
            notifications.push({
              notification: {
                title: 'Rappel de rendez-vous',
                body: `N'oubliez pas votre rendez-vous demain: "${appointment.subject}"`,
              },
              data: {
                type: 'appointment_reminder',
                appointmentId: doc.id,
              },
              token: requester.fcmToken,
            });
          }
        }
      }
    }

    // Envoyer toutes les notifications
    if (notifications.length > 0) {
      const results = await Promise.allSettled(
        notifications.map(notification => admin.messaging().send(notification))
      );
      
      const successCount = results.filter(result => result.status === 'fulfilled').length;
      console.log(`${successCount}/${notifications.length} rappels envoyés avec succès`);
    } else {
      console.log('Aucun rappel à envoyer aujourd\'hui');
    }
  } catch (error) {
    console.error('Erreur lors de l\'envoi des rappels:', error);
  }
});
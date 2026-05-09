import * as functionsV1 from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

admin.initializeApp();

const db = admin.firestore();

export const onUpdateMatchResult = functionsV1.firestore
  .document('matches/{matchId}')
  .onWrite(async (change, context) => {
    const { matchId } = context.params;

    const newData = change.after.data();
    if (!newData || !newData.result) {
      return null;
    }

    const result = newData.result;
    const players = newData.players as string[];

    if (!result.newElo || !result.eloChanges || !result.scores) {
      console.log(`Match ${matchId}: Estructura de 'result' incompleta`);
      return null;
    }

    const winnerId = result.winnerId as string | null;
    const newElo = result.newElo as { [userId: string]: number };
    const eloChanges = result.eloChanges as { [userId: string]: number };

    const batch = db.batch();

    for (const userId of players) {
      const userRef = db.collection('users').doc(userId);

      batch.update(userRef, { elo: newElo[userId] });

      const statsUpdate: Record<string, any> = {
        'stats.totalGames': admin.firestore.FieldValue.increment(1),
      };

      if (winnerId) {
        if (userId === winnerId) {
          statsUpdate['stats.wins'] = admin.firestore.FieldValue.increment(1);
          statsUpdate['stats.currentWinStreak'] =
            admin.firestore.FieldValue.increment(1);
        } else {
          statsUpdate['stats.losses'] = admin.firestore.FieldValue.increment(1);
          statsUpdate['stats.currentWinStreak'] = 0;
        }
      } else {
        statsUpdate['stats.draws'] = admin.firestore.FieldValue.increment(1);
      }

      batch.update(userRef, statsUpdate);

      console.log(
        `Match ${matchId}: Actualizando usuario ${userId}: ` +
          `ELO ${newElo[userId]} (${eloChanges[userId]} puntos)`
      );
    }

    await batch.commit();

    console.log(`Match ${matchId}: ELOs y estadísticas actualizados correctamente`);

    return null;
  });

export const onCreateUser = functionsV1.firestore
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const { userId } = context.params;
    const data = snap.data();

    const needsInit = data.elo === undefined || data.stats === undefined;

    if (needsInit) {
      const updates: { [key: string]: any } = {
        elo: 1000,
      };

      if (!data.stats) {
        updates.stats = {
          totalGames: 0,
          wins: 0,
          losses: 0,
          draws: 0,
          totalCorrectAnswers: 0,
          currentWinStreak: 0,
          bestWinStreak: 0,
        };
      }

      await snap.ref.update(updates);
      console.log(`Usuario ${userId} inicializado con valores por defecto`);
    }

    return null;
  });

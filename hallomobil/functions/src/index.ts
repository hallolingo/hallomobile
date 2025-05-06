// Firebase fonksiyonları için gerekli modülleri içe aktar
import * as firestore from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// Kullanıcı işlemleri için trigger'lar
export const trackUserChanges = firestore.onDocumentWritten(
    {
        document: "users/{userId}",
        region: "europe-west3",
    },

    async (event) => {
        const change = event.data;
        if (!change) return;

        if (!change.after.exists) {
            // Kullanıcı silindi
            await logActivity(
                "user_removed",
                `Kullanıcı silindi: ${change.before.data()?.name || event.params.userId
                }`,
                change.before.data()
            );
        } else if (!change.before.exists) {
            // Yeni kullanıcı oluşturuldu
            await logActivity(
                "user_added",
                `Yeni kullanıcı eklendi: ${change.after.data()?.name || event.params.userId
                }`,
                change.after.data()
            );
        } else {
            // Kullanıcı güncellendi
            const beforeData = change.before.data();
            const afterData = change.after.data();

            // Değişen alanları tespit et
            const changedFields = getChangedFields(beforeData, afterData);

            if (changedFields.length > 0) {
                await logActivity(
                    "user_updated",
                    `Kullanıcı güncellendi: ${afterData?.name || event.params.userId
                    } (Değişen alanlar: ${changedFields.join(", ")})`,
                    afterData
                );
            }
        }
    }
);

// Dil işlemleri için trigger'lar
export const trackLanguageChanges = firestore.onDocumentWritten(

    {
        document: "languages/{langId}",
        region: "europe-west3",
    },
    async (event) => {
        const change = event.data;
        if (!change) return;

        if (!change.after.exists) {
            // Dil silindi
            await logActivity(
                "language_removed",
                `Dil silindi: ${change.before.data()?.name || event.params.langId}`,
                change.before.data()
            );
        } else if (!change.before.exists) {
            // Yeni dil eklendi
            await logActivity(
                "language_added",
                `Yeni dil eklendi: ${change.after.data()?.name || event.params.langId
                }`,
                change.after.data()
            );
        } else {
            // Dil güncellendi
            const beforeData = change.before.data();
            const afterData = change.after.data();

            const changedFields = getChangedFields(beforeData, afterData);

            if (changedFields.length > 0) {
                await logActivity(
                    "language_updated",
                    `Dil güncellendi: ${afterData?.name || event.params.langId
                    } (Değişen alanlar: ${changedFields.join(", ")})`,
                    afterData
                );
            }
        }
    }
);

/**
 * @param {string} type - Aktivite tipi
 * @param {string} description - Aktivite açıklaması
 * @param {admin.firestore.DocumentData | undefined} data 
 * @return {Promise<admin.firestore.DocumentReference>} 
 */
async function logActivity(
    type: string,
    description: string,
    data: admin.firestore.DocumentData | undefined
) {
    const activityData: Record<string, unknown> = {
        type,
        description,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        read: false
    };

    if (data) {
        activityData.metadata = {
            id: data.id || data.uid,
            name: data.name,
            email: data.email,
        };
    }

    return db.collection("activities").add(activityData);
}

/**
 * İki doküman arasında değişen alanları tespit eder
 * @param {admin.firestore.DocumentData | undefined} before - Önceki doküman verisi
 * @param {admin.firestore.DocumentData | undefined} after - Sonraki doküman verisi
 * @return {string[]} - Değişen alan isimleri dizisi
 */
function getChangedFields(
    before: admin.firestore.DocumentData | undefined,
    after: admin.firestore.DocumentData | undefined
): string[] {
    if (!before || !after) return [];

    const changedFields: string[] = [];
    const allKeys = new Set([...Object.keys(before), ...Object.keys(after)]);

    allKeys.forEach((key) => {
        if (JSON.stringify(before[key]) !== JSON.stringify(after[key])) {
            changedFields.push(key);
        }
    });

    return changedFields;
}
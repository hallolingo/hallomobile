// Firebase fonksiyonları için gerekli modülleri içe aktar
import * as firestore from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import * as nodemailer from "nodemailer";
import { onSchedule } from "firebase-functions/v2/scheduler";

admin.initializeApp();
const db = admin.firestore();


const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
        user: "yusudhan.02@gmail.com",
        pass: "pylb lijs cqlu dlgi",
    },
});

export const sendWelcomeEmail = firestore.onDocumentCreated(
    {
        document: "users/{userId}",
        region: "europe-west3",
    },
    async (event) => {
        const userData = event.data?.data();
        if (!userData) {
            console.log("User data not found");
            return;
        }

        const email = userData.email;
        const name = userData.name || "Kullanıcı";

        if (!email) {
            console.log("Email address not found for user:", event.params.userId);
            return;
        }

        const logoUrl = 'https://firebasestorage.googleapis.com/v0/b/hallolingo-739a8.firebasestorage.app/o/logos%2FbigLogo.jpeg?alt=media&token=5d75d892-ad61-4983-a5bb-b5c4adc5e776';

        const htmlTemplate = `
        <!DOCTYPE html>
        <html lang="tr">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: 'Arial', sans-serif;
                    background-color: #f4f4f4;
                    margin: 0;
                    padding: 0;
                    color: #333;
                }
                .container {
                    max-width: 600px;
                    margin: 20px auto;
                    background-color: #ffffff;
                    border-radius: 10px;
                    overflow: hidden;
                    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
                }
                .header {
                    background-color: #4a90e2;
                    padding: 20px;
                    text-align: center;
                }
                .header img {
                    max-width: 150px;
                    height: auto;
                }
                .content {
                    padding: 30px;
                    text-align: center;
                }
                .content h1 {
                    font-size: 24px;
                    color: #4a90e2;
                    margin-bottom: 20px;
                }
                .content p {
                    font-size: 16px;
                    line-height: 1.5;
                    color: #555;
                    margin-bottom: 20px;
                }
                .button {
                    display: inline-block;
                    padding: 12px 24px;
                    background-color: #4a90e2;
                    color: #ffffff;
                    text-decoration: none;
                    border-radius: 8px;
                    font-weight: bold;
                    margin: 20px 0;
                }
                .footer {
                    background-color: #f4f4f4;
                    padding: 20px;
                    text-align: center;
                    font-size: 14px;
                    color: #777;
                }
                .footer a {
                    color: #4a90e2;
                    text-decoration: none;
                }
                @media only screen and (max-width: 600px) {
                    .container {
                        margin: 10px;
                    }
                    .content h1 {
                        font-size: 20px;
                    }
                    .button {
                        font-size: 14px;
                        padding: 10px 20px;
                    }
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <img src="${logoUrl}" alt="Hallolingo Logo">
                </div>
                <div class="content">
                    <h1>Hallolingo'ya Hoş Geldiniz!</h1>
                    <p>Merhaba ${name},</p>
                    <p>Hallolingo ailesine katıldığınız için çok heyecanlıyız! Artık Almanca öğrenme yolculuğunuzda size eşlik etmek için buradayız. Eğlenceli, etkileşimli ve etkili öğrenme yöntemlerimizle Almanca'yı kolayca öğrenebileceksiniz.</p>
                    <p>Hemen başlayarak dil becerilerinizi geliştirmeye ne dersiniz? İlk dersinize başlamak için aşağıdaki butona tıklayın:</p>
                    <a href="https://hallo.com/start" class="button">Öğrenmeye Başla</a>
                    <p>Herhangi bir sorunuz varsa, destek ekibimiz size yardımcı olmaktan mutluluk duyar. Öğrenme yolculuğunuzda başarılar dileriz!</p>
                </div>
                <div class="footer">
                    <p>© ${new Date().getFullYear()} Hallolingo. Tüm hakları saklıdır.</p>
                    <p><a href="https://hallo.com">Bize Ulaşın</a> | <a href="https://hallo.com/privacy">Gizlilik Politikası</a></p>
                </div>
            </div>
        </body>
        </html>
        `;

        const mailOptions = {
            from: 'HALLOLINGO <info@hallo.com>',
            to: email,
            subject: 'Hallolingo’ya Hoş Geldiniz! Almanca Öğrenme Yolculuğunuz Başlıyor',
            html: htmlTemplate,
        };

        try {
            await transporter.sendMail(mailOptions);
            console.log(`Welcome email sent to ${email}`);
            await logUserActivity(
                "welcome_email_sent",
                `Hoş geldiniz e-postası gönderildi: ${name} (${email})`,
                userData
            );
        } catch (error) {
            console.error(`Error sending welcome email to ${email}:`, error);
        }
    }
);
// Add this near your other exports
export const deleteExpiredVerificationCodes = onSchedule(
    { schedule: "every 5 minutes", region: "europe-west3" },
    async (event) => {
        const now = admin.firestore.Timestamp.now();
        const fiveMinutesAgo = new admin.firestore.Timestamp(
            now.seconds - 300,
            now.nanoseconds
        );

        try {
            const snapshot = await db.collection('verificationCodes')
                .where('createdAt', '<=', fiveMinutesAgo)
                .get();

            const batch = db.batch();
            snapshot.docs.forEach(doc => {
                batch.delete(doc.ref);
            });

            await batch.commit();
            console.log(`Deleted ${snapshot.size} expired verification codes`);
        } catch (error) {
            console.error('Error deleting expired codes:', error);
        }
    }
);

// Kullanıcı işlemleri için trigger
export const trackUserChanges = firestore.onDocumentWritten(
    {
        document: "users/{userId}",
        region: "europe-west3",
    },
    async (event) => {
        console.log("trackUserChanges tetiklendi:", event.params);
        const change = event.data;
        if (!change) {
            console.log("Change verisi yok");
            return;
        }

        const userId = event.params.userId;

        if (!change.after.exists) {
            // Kullanıcı silindi
            console.log("Kullanıcı silindi:", change.before.data());
            await logUserActivity(
                "user_removed",
                `Kullanıcı silindi: ${change.before.data()?.name || userId}`,
                change.before.data()
            );
        } else if (!change.before.exists) {
            // Yeni kullanıcı oluşturuldu
            console.log("Yeni kullanıcı eklendi:", change.after.data());
            await logUserActivity(
                "user_added",
                `Yeni kullanıcı eklendi: ${change.after.data()?.name || userId}`,
                change.after.data()
            );
        } else {
            // Kullanıcı güncellendi
            const beforeData = change.before.data();
            const afterData = change.after.data();
            const changedFields = getChangedFields(beforeData, afterData);

            if (changedFields.length > 0) {
                console.log("Kullanıcı güncellendi, değişen alanlar:", changedFields);
                await logUserActivity(
                    "user_updated",
                    `Kullanıcı güncellendi: ${afterData?.name || userId} (Değişen alanlar: ${changedFields.join(", ")})`,
                    afterData
                );
            }
        }
    }
);

// Dil işlemleri için trigger
export const trackLanguageChanges = firestore.onDocumentWritten(
    {
        document: "languages/{langId}",
        region: "europe-west3",
    },
    async (event) => {
        console.log("trackLanguageChanges tetiklendi:", event.params);
        const change = event.data;
        if (!change) {
            console.log("Change verisi yok");
            return;
        }

        const langId = event.params.langId;

        if (!change.after.exists) {
            // Dil silindi
            console.log("Dil silindi:", change.before.data());
            await logLanguageActivity(
                "language_removed",
                `Dil silindi: ${change.before.data()?.name || langId}`,
                change.before.data()
            );
        } else if (!change.before.exists) {
            // Yeni dil eklendi
            console.log("Yeni dil eklendi:", change.after.data());
            await logLanguageActivity(
                "language_added",
                `Yeni dil eklendi: ${change.after.data()?.name || langId}`,
                change.after.data()
            );
        } else {
            // Dil güncellendi
            const beforeData = change.before.data();
            const afterData = change.after.data();
            const changedFields = getChangedFields(beforeData, afterData);

            if (changedFields.length > 0) {
                console.log("Dil güncellendi, değişen alanlar:", changedFields);
                await logLanguageActivity(
                    "language_updated",
                    `Dil güncellendi: ${afterData?.name || langId} (Değişen alanlar: ${changedFields.join(", ")})`,
                    afterData
                );
            }
        }
    }
);

export const trackWordsChanges = firestore.onDocumentWritten(
    {
        document: "words/{langId}/{level}/exercises/items/{exerciseId}",
        region: "europe-west3",
    },
    async (event) => {
        console.log("trackWordsChanges tetiklendi:", event.params);
        const change = event.data;
        if (!change) {
            console.log("Change verisi yok");
            return;
        }

        const langId = event.params.langId;
        const level = event.params.level;
        const exerciseId = event.params.exerciseId;

        console.log("LangId:", langId, "Level:", level, "ExerciseId:", exerciseId);

        if (!change.after.exists) {
            console.log("Words egzersizi silindi:", change.before.data());
            await logWordsActivity(
                "words_removed",
                `Kelime egzersizi silindi: ${langId}/${level}/${exerciseId}`,
                change.before.data()
            );
        } else if (!change.before.exists) {
            console.log("Yeni words egzersizi eklendi:", change.after.data());
            await logWordsActivity(
                "words_added",
                `Yeni Kelime egzersizi eklendi: ${langId}/${level}/${exerciseId}`,
                change.after.data()
            );
        } else {
            const changedFields = getChangedFields(
                change.before.data(),
                change.after.data()
            );
            console.log("Değişen alanlar:", changedFields);
            if (changedFields.length > 0) {
                await logWordsActivity(
                    "words_updated",
                    `Kelime egzersizi güncellendi: ${langId}/${level}/${exerciseId} (Değişen alanlar: ${changedFields.join(", ")})`,
                    change.after.data()
                );
            }
        }
    }
);

export const sendVerificationEmail = functions.https.onRequest(
    async (req, res) => {
        const { email, code } = req.body;

        if (!email || !code) {
            res.status(400).send("Email ve kod gereklidir");
            return;
        }

        const logoUrl = 'https://firebasestorage.googleapis.com/v0/b/hallolingo-739a8.firebasestorage.app/o/logos%2FbigLogo.jpeg?alt=media&token=5d75d892-ad61-4983-a5bb-b5c4adc5e776';

        const htmlTemplate = `
        <!DOCTYPE html>
        <html lang="tr">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: 'Arial', sans-serif;
                    background-color: #f4f4f4;
                    margin: 0;
                    padding: 0;
                    color: #333;
                }
                .container {
                    max-width: 600px;
                    margin: 20px auto;
                    background-color: #ffffff;
                    border-radius: 10px;
                    overflow: hidden;
                    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
                }
                .header {
                    background-color: #4a90e2;
                    padding: 20px;
                    text-align: center;
                }
                .header img {
                    max-width: 150px;
                    height: auto;
                }
                .content {
                    padding: 30px;
                    text-align: center;
                }
                .content h1 {
                    font-size: 24px;
                    color: #4a90e2;
                    margin-bottom: 20px;
                }
                .content p {
                    font-size: 16px;
                    line-height: 1.5;
                    color: #555;
                    margin-bottom: 20px;
                }
                .code-box {
                    display: inline-block;
                    background-color: #f1f1f1;
                    padding: 15px 25px;
                    border-radius: 8px;
                    font-size: 24px;
                    font-weight: bold;
                    color: #333;
                    letter-spacing: 5px;
                    margin: 20px 0;
                }
                .footer {
                    background-color: #f4f4f4;
                    padding: 20px;
                    text-align: center;
                    font-size: 14px;
                    color: #777;
                }
                .footer a {
                    color: #4a90e2;
                    text-decoration: none;
                }
                @media only screen and (max-width: 600px) {
                    .container {
                        margin: 10px;
                    }
                    .content h1 {
                        font-size: 20px;
                    }
                    .code-box {
                        font-size: 20px;
                        padding: 10px 20px;
                    }
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <img src="${logoUrl}" alt="Hallolingo Logo">
                </div>
                <div class="content">
                    <h1>Doğrulama Kodunuz</h1>
                    <p>Merhaba,</p>
                    <p>Hesabınızı doğrulamak için aşağıdaki 6 haneli kodu kullanabilirsiniz:</p>
                    <div class="code-box">${code}</div>
                    <p>Bu kod 5 dakika boyunca geçerlidir. Eğer bu işlemi siz başlatmadıysanız, lütfen bizimle iletişime geçin.</p>
                    <p>E-postayı göremiyorsanız, lütfen spam veya gereksiz posta klasörünüzü kontrol edin.</p>
                </div>
                <div class="footer">
                    <p>&copy; ${new Date().getFullYear()} Hallolingo. Tüm hakları saklıdır.</p>
                    <p><a href="https://hallo.com">Bize Ulaşın</a> | <a href="https://hallo.com/privacy">Gizlilik Politikası</a></p>
                </div>
            </div>
        </body>
        </html>
    `;

        const mailOptions = {
            from: 'HALLOLINGO <info@hallo.com>',
            to: email,
            subject: 'Hallolingo Doğrulama Kodu',
            html: htmlTemplate,
        };

        try {
            await transporter.sendMail(mailOptions);
            res.status(200).send("Email gönderildi");
        } catch (error) {
            console.error("Email gönderilirken hata:", error);
            res.status(500).send("Email gönderilemedi");
        }
    }
);

/**
 * Kullanıcı aktivitelerini kaydeder
 * @param {string} type - Aktivite tipi
 * @param {string} description - Aktivite açıklaması
 * @param {admin.firestore.DocumentData | undefined} data - Kullanıcı verisi
 * @return {Promise<admin.firestore.DocumentReference>}
 */
async function logUserActivity(
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
        try {
            activityData.metadata = {
                id: data.id || data.uid || "unknown",
                name: data.name || "unknown",
                email: data.email || null,
            };
        } catch (error) {
            console.error("logUserActivity: Metadata oluştururken hata:", error);
        }
    }

    try {
        const docRef = await db.collection("activities").add(activityData);
        console.log("logUserActivity: Etkinlik kaydedildi:", docRef.id, activityData);
        return docRef;
    } catch (error) {
        console.error("logUserActivity: Etkinlik kaydedilirken hata:", error);
        throw error;
    }
}

/**
 * Dil aktivitelerini kaydeder
 * @param {string} type - Aktivite tipi
 * @param {string} description - Aktivite açıklaması
 * @param {admin.firestore.DocumentData | undefined} data - Dil verisi
 * @return {Promise<admin.firestore.DocumentReference>}
 */
async function logLanguageActivity(
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
        try {
            activityData.metadata = {
                id: data.id || "unknown",
                name: data.name || "unknown",
                // Dil için ek alanlar eklenebilir
            };
        } catch (error) {
            console.error("logLanguageActivity: Metadata oluştururken hata:", error);
        }
    }

    try {
        const docRef = await db.collection("activities").add(activityData);
        console.log("logLanguageActivity: Etkinlik kaydedildi:", docRef.id, activityData);
        return docRef;
    } catch (error) {
        console.error("logLanguageActivity: Etkinlik kaydedilirken hata:", error);
        throw error;
    }
}

/**
 * @param {string} type - Aktivite tipi
 * @param {string} description - Aktivite açıklaması
 * @param {admin.firestore.DocumentData | undefined} data 
 * @return {Promise<admin.firestore.DocumentReference>}
 */
async function logWordsActivity(
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
        try {
            activityData.metadata = {
                id: data.id || "unknown",
                fullSentence: data.fullSentence || null,
                hiddenWord: data.hiddenWord || null,
                option1: data.option1 || null,
                option2: data.option2 || null,
                correctOption: data.correctOption || null,
                imageUrl: data.imageUrl || null,
            };
        } catch (error) {
            console.error("logWordsActivity: Metadata oluştururken hata:", error);
        }
    }

    try {
        const docRef = await db.collection("activities").add(activityData);
        console.log("logWordsActivity: Etkinlik kaydedildi:", docRef.id, activityData);
        return docRef;
    } catch (error) {
        console.error("logWordsActivity: Etkinlik kaydedilirken hata:", error);
        throw error;
    }
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
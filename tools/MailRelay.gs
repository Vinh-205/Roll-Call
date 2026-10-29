/** Google Apps Script Mail Relay for CatCheck. No passwords in this file. */
function initializeRelay() {
  var properties = PropertiesService.getScriptProperties();
  if (!properties.getProperty('CATCHECK_SECRET')) {
    properties.setProperty('CATCHECK_SECRET', Utilities.getUuid() + Utilities.getUuid());
  }
  // Running this function authorizes MailApp and checks the remaining allowance; it sends no email.
  MailApp.getRemainingDailyQuota();
}
function doPost(event) {
  var result = {ok:false};
  try {
    var payload = JSON.parse(event.postData.contents);
    var secret = PropertiesService.getScriptProperties().getProperty('CATCHECK_SECRET');
    if (!secret || payload.secret !== secret) throw new Error('Unauthorized');
    if (!/^\S+@\S+\.\S+$/.test(payload.to) || !String(payload.subject).startsWith('CatCheck')) throw new Error('Invalid request');
    if (String(payload.text).length > 2000) throw new Error('Message too long');
    MailApp.sendEmail({to:payload.to,subject:payload.subject,body:payload.text,name:'CatCheck · 4 con mèo'});
    result = {ok:true};
  } catch(error) { result = {ok:false}; }
  return ContentService.createTextOutput(JSON.stringify(result)).setMimeType(ContentService.MimeType.JSON);
}

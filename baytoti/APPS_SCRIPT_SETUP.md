# Baytoti — Google Apps Script setup

One-time setup to persist purchases to your Google Sheet.

## 1. Open the Apps Script editor

- Open your sheet: https://docs.google.com/spreadsheets/d/12xFYUN9pGX3dXcRVwFVzzUqupXur3pEuJy9a9gby4jQ/edit
- **Extensions → Apps Script** (opens a new tab)

## 2. Paste the code

Delete the default `function myFunction()` stub, then paste the entire block below:

```javascript
// ============================================================
//  Baytoti — Google Apps Script backend
// ============================================================

const SHEET_NAME = 'Purchases';
const HEADERS = ['listId', 'id', 'itemName', 'price', 'category', 'addedByName', 'date'];

function getSheet_() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sh = ss.getSheetByName(SHEET_NAME);
  if (!sh) {
    sh = ss.insertSheet(SHEET_NAME);
    sh.appendRow(HEADERS);
  }
  return sh;
}

function json_(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}

function doGet(e) {
  try {
    const listId = (e && e.parameter && e.parameter.listId) || '';
    const sh = getSheet_();
    const values = sh.getDataRange().getValues();
    const header = values.shift() || HEADERS;
    const data = values
      .map(row => {
        const o = {};
        header.forEach((h, i) => { o[h] = row[i]; });
        return o;
      })
      .filter(r => r.id && (!listId || String(r.listId) === String(listId)))
      .map(r => ({
        id: String(r.id),
        itemName: String(r.itemName || ''),
        price: r.price === '' || r.price === null ? null : Number(r.price),
        category: String(r.category || ''),
        addedByName: String(r.addedByName || ''),
        date: r.date instanceof Date ? r.date.toISOString() : String(r.date || '')
      }));
    return json_({ ok: true, data });
  } catch (err) {
    return json_({ ok: false, error: String(err) });
  }
}

function doPost(e) {
  try {
    const body = JSON.parse((e && e.postData && e.postData.contents) || '{}');
    const action = body.action;
    const listId = String(body.listId || '');
    const sh = getSheet_();

    if (action === 'add') {
      const p = body.purchase || {};
      sh.appendRow([
        listId,
        String(p.id || ''),
        String(p.itemName || ''),
        p.price == null ? '' : Number(p.price),
        String(p.category || ''),
        String(p.addedByName || ''),
        String(p.date || new Date().toISOString())
      ]);
      return json_({ ok: true });
    }

    if (action === 'update') {
      const p = body.purchase || {};
      const values = sh.getDataRange().getValues();
      for (let i = 1; i < values.length; i++) {
        if (String(values[i][1]) === String(p.id) && String(values[i][0]) === listId) {
          sh.getRange(i + 1, 1, 1, HEADERS.length).setValues([[
            listId,
            String(p.id || ''),
            String(p.itemName || ''),
            p.price == null ? '' : Number(p.price),
            String(p.category || ''),
            String(p.addedByName || ''),
            String(p.date || values[i][6] || new Date().toISOString())
          ]]);
          return json_({ ok: true });
        }
      }
      return json_({ ok: false, error: 'not found' });
    }

    if (action === 'delete') {
      const id = String(body.id || '');
      const values = sh.getDataRange().getValues();
      for (let i = 1; i < values.length; i++) {
        if (String(values[i][1]) === id && String(values[i][0]) === listId) {
          sh.deleteRow(i + 1);
          return json_({ ok: true });
        }
      }
      return json_({ ok: false, error: 'not found' });
    }

    return json_({ ok: false, error: 'unknown action' });
  } catch (err) {
    return json_({ ok: false, error: String(err) });
  }
}
```

## 3. Save and deploy

1. Click the 💾 Save icon (or Ctrl/Cmd+S)
2. Click **Deploy → New deployment**
3. Click the gear ⚙ next to "Select type" → choose **Web app**
4. Fill in:
   - Description: `baytoti`
   - Execute as: **Me**
   - Who has access: **Anyone**
5. Click **Deploy**
6. Approve the OAuth prompt: **Advanced → Go to … (unsafe) → Allow**
7. Copy the **Web app URL** (looks like `https://script.google.com/macros/s/XXXX/exec`)

## 4. Give me the URL

Paste the Web app URL back in the chat. I'll drop it into `WEB_APP_URL` in `bayti.html` and push the change.

## Data model

A new tab named **Purchases** is auto-created with these columns:

| listId | id | itemName | price | category | addedByName | date |
|--------|----|-|------:|----------|-------------|------|

- `listId` separates different users' lists (from the `?list=…` URL param)
- One row per purchase. Delete/update by matching `listId` + `id`.

import { google } from 'googleapis';
import { join } from 'path';

import type { Computer } from './index.d';

const SCOPES = ['https://www.googleapis.com/auth/spreadsheets'];

const SPREADSHEET_ID = process.env.SPREADSHEET_ID;
const sheetId = Number(process.env.SHEET_ID);
const tableId = process.env.TABLE_ID;

const auth = new google.auth.GoogleAuth({
    keyFile: process.env.CREDENTIALS || join(__dirname, '..', 'credentials.json'),
    scopes: SCOPES,
});

const sheets = google.sheets({ version: 'v4', auth });

// Utils
const steps = ['Initialisation', 'Effacement', 'Installation', 'Terminée', 'Erreur'];

const bindStepToName = (step: number): string => {
    if (step < 0 || step >= steps.length) return `Étape inconnue`;
    return steps[step];
}

const computerToRow = (data: Computer): (string | number | null)[][] => {
    const h = (value: string) => value ?? null; // Helper to convert undefined to null

    const withStep = typeof data.step === 'number'; // Évite de comparer data.step à null ou undefined
    const parsedDate = new Date().toLocaleString('fr-FR', { timeZone: 'Europe/Paris' });

    const values = [
        [
            "=ROW()-1", // Id
            withStep ? bindStepToName(data.step) : null,
            data.since ?? (withStep ? parsedDate : null),
            h(data.macAddress),
            h(data.model),
            h(data.processor),
            data.ram ? Math.round(Number(data.ram) / 1024 / 1024) : null, // Convert the RAM amount from kB to GB
            data.ramSlots ? `${data.freeRamSlots}/${data.ramSlots}` : null, // Free RAM slots / Total RAM slots
            h(data.diskSize),
            h(data.gpu),
        ]
    ];

    return values;
}

// Sheet actions
/**
 * Get the line number of the computer with the given MAC address. If the computer is not found, return null.
 * @param macAddress 
 * @returns The line number of the computer (starting from 1), or null if not found.
 */
export const getComputerLine = async (macAddress: string) => {
    // Column D (i = 3) contains the MAC addresses
    const range = 'A:D';
    const response = await sheets.spreadsheets.values.get({
        spreadsheetId: SPREADSHEET_ID,
        range,
    });

    const rows = response.data.values;
    if (!rows) return null;

    for (let i = 1; i < rows.length; i++) {
        const row = rows[i];
        if (row[3]?.toLowerCase() === macAddress.toLowerCase()) return i;
    }

    return null;
}

export const addComputerLine = async (data: Computer) => {
    const values = computerToRow(data)[0]; // On récupère le premier tableau de valeurs

    // Convert values in "RowData" for the API
    const rowData = values.map(val => {
        let valueType = 'stringValue';
        if (typeof val === 'number') valueType = 'numberValue';
        else if (val?.startsWith('=')) valueType = 'formulaValue';

        return {
            'userEnteredValue': { [valueType]: val ? val.toString() : "" }
        };
    });

    await sheets.spreadsheets.batchUpdate({
        spreadsheetId: SPREADSHEET_ID,
        requestBody: {
            requests: [
                {
                    appendCells: {
                        sheetId,
                        tableId,
                        rows: [{ values: rowData }],
                        fields: "userEnteredValue"
                    }
                }
            ]
        }
    });
}

export const updateComputerLine = async (line: number, data: Computer) => {
    const values = computerToRow(data);

    await sheets.spreadsheets.values.update({
        spreadsheetId: SPREADSHEET_ID,
        range: `A${line + 1}:J${line + 1}`,
        valueInputOption: 'USER_ENTERED',
        requestBody: {
            values
        }
    });
}
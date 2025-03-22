const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');

// Prepare the database
const db = require('better-sqlite3')('aims.db');

// Create the computer table
db.exec('CREATE TABLE IF NOT EXISTS computer (mac_address TEXT PRIMARY KEY, number TEXT, model TEXT, processor TEXT, ram TEXT, ram_slots TEXT, free_ram_slots TEXT, disk_size TEXT, gpu TEXT, step INTEGER, since TEXT)');
db.exec('CREATE TABLE IF NOT EXISTS ignored (mac_address TEXT PRIMARY KEY)');

// Prepare some SQL queries
const find = db.prepare('SELECT * FROM computer WHERE mac_address = ?');
const insert = db.prepare('INSERT INTO computer (mac_address, step, since) VALUES (?, ?, ?)');
const updateStep = db.prepare('UPDATE computer SET step = ?, since = ? WHERE mac_address = ?');
const remove = db.prepare('DELETE FROM computer WHERE mac_address = ?');

const addIgnore = db.prepare('INSERT INTO ignored (mac_address) VALUES (?)');
const findIgnore = db.prepare('SELECT * FROM ignored WHERE mac_address = ?');

// Setup the express app
const app = express();

app.use(bodyParser.json());
app.use(cors());

/**
 * Get all computers
 */
app.get('/computers', async (req, res) => {
    const computers = db.prepare('SELECT * FROM computer').all();
    res.json(computers);
});

const now = () => new Date().toString();

/**
 * Register a new computer who got an IP address from the DHCP server, even if the format is not correct.
 * Body example:
 * { "mac_address": "00:00:00:00:00:00:XX" }
 */
app.post('/computer', (req, res) => {
    const { mac_address: rawMacAddress } = req.body;

    // Format the MAC address
    // Make sure each part is 2 characters long and only keep the first 6 parts
    // This correct potential issues with the DHCP server
    const mac_address = rawMacAddress.split(':').map((part) => part.padStart(2, '0')).slice(0, 6).join(':');

    // Check if the computer should be ignored
    const ignored = findIgnore.get(mac_address);
    if (ignored) return res.status(204).end();

    const step = 0;

    // Check if the computer is already registered
    const computer = find.get(mac_address);
    if (!computer) {
        // Insert the new computer
        insert.run(mac_address, step, now());
        res.status(201).end();
    } else if (computer.step === 0) {
        // If step 0, it means another DHCP request has been made by the same computer. It's normally due to Anaconda installation. Don't do nothing
        return res.status(204).end();
    } else {
        // Resintallation: the DHCP just provided a new IP address to the computer.
        // Set the step to 0 and update the since field.
        updateStep.run(0, now(), mac_address);
        res.status(204).end();
    }
});

/**
 * Update a computer information 
 * For example, when the pre-script run, the step will be updated to 1 (installatin begins just after the pre-script).
 * The pre-script also send recensement data (model, processor, ram, ram_slots, free_ram_slots, disk_size, gpu).
 * This can also be used to update the step (post-install script), or the number (from AIMS website).
 */
app.patch('/computer/:mac_address', (req, res) => {
    const { mac_address } = req.params;

    // Handle the data
    const data = req.body;
    if (data.step) data.since = now();

    // Split keys and values
    const keys = Object.keys(data);
    const values = Object.values(data);

    // Store the updated data (warning: no validation is done here)
    const update = db.prepare(`UPDATE computer SET ${keys.map(k => `${k} = ?`).join(', ')} WHERE mac_address = ?`)
    update.run(...values, mac_address);

    res.status(204).end();
});

/**
 * Remove a computer from the database
 */
app.delete('/computer/:mac_address', (req, res) => {
    const { mac_address } = req.params;
    remove.run(mac_address);

    res.status(204).end();
});

/**
 * Ignore a computer
 * This allows external computers to connect to the DHCP server without being listed on AIMS.
 */
app.post('/ignore/:mac_address', (req, res) => {
    const { mac_address } = req.params;
    addIgnore.run(mac_address);

    res.status(201).end();
});

app.listen(5000, () => console.log("AIMS api listening on port 5000"));
import { Router } from 'express';
import { Request, Response } from 'express';
import { getComputerLine, addComputerLine, updateComputerLine } from './google-sheet';

import type { Computer } from './index.d';

export const computerRouter = Router();

/**
 * Register a new computer who got an IP address from the DHCP server, even if the format is not correct.
 * Body example:
 * { "mac_address": "0:00:00:0:00:00:XX" }
 */
computerRouter.post('/:macAddress', async (req: Request, res: Response) => {
    let macAddress = req.params.macAddress as string;
    if (!macAddress) return res.status(400).json({ error: 'MAC address is required' });

    // Make sure macAddress is in the correct format
    macAddress = macAddress.toLowerCase().split(':').map(part => part.padStart(2, '0')).join(':');

    const step = 0;

    // Check if the computer is already registered
    const computerLine = await getComputerLine(macAddress);

    // If the computer is already registered, either Anaconda just started, or the computer got a new IP address. In both cases, we update the step just in case.
    if (computerLine) {
        updateComputerLine(computerLine, { macAddress, step });
        res.status(204).end();
        return;
    }

    // Insert the new computer
    addComputerLine({ macAddress, step });
    res.status(201).end();
    return;
});

/**
 * Update the computer informations. This endpoint is called by Anaconda.
 */
computerRouter.patch('/:macAddress', async (req: Request, res: Response) => {
    const macAddress = req.params.macAddress as string;
    if (!macAddress) return res.status(400).json({ error: 'MAC address is required' });

    // Handle the data
    const data: Computer = req.body;

    // Get the computer line
    const computerLine = await getComputerLine(macAddress);

    // Perform the operation
    if (!computerLine) addComputerLine({ macAddress, ...data });
    else updateComputerLine(computerLine, data);

    res.status(204).end();
});
import { Router } from 'express';
import { Request, Response } from 'express';
import { upsertComputerLine } from './google-sheet';

import type { Computer } from './index.d';

export const computerRouter = Router();

/**
 * Register a new computer who got an IP address from the DHCP server.
 */
computerRouter.post('/:macAddress', async (req: Request, res: Response) => {
    let macAddress = req.params.macAddress as string;
    if (!macAddress) return res.status(400).json({ error: 'MAC address is required' });

    // Make sure macAddress is in the correct format
    macAddress = macAddress.toLowerCase().split(':').map(part => part.padStart(2, '0')).join(':');

    const step = 0;

    // Handle the data
    upsertComputerLine({ macAddress, step });
});

/**
 * Update the computer informations. This endpoint is called by Anaconda.
 */
computerRouter.patch('/:macAddress', async (req: Request, res: Response) => {
    const macAddress = req.params.macAddress as string;
    if (!macAddress) return res.status(400).json({ error: 'MAC address is required' });

    // Handle the data
    const data: Computer = req.body;
    upsertComputerLine({ macAddress, ...data });

    res.status(204).end();
});
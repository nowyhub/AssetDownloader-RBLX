const express = require('express');
const cors = require('cors');
const axios = require('axios');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Root endpoint - This was missing!
app.get('/', (req, res) => {
    res.json({
        success: true,
        message: 'Roblox Asset API is running!',
        version: '1.0.0',
        endpoints: {
            health: '/api/health',
            download: '/api/download'
        },
        usage: {
            health_check: 'GET /api/health',
            download_asset: 'POST /api/download with { assetId, robloxCookie?, placeId? }'
        }
    });
});

// API Routes
app.get('/api/health', (req, res) => {
    res.json({
        success: true,
        status: 'online',
        timestamp: new Date().toISOString(),
        message: 'API is healthy and ready to process requests'
    });
});

app.post('/api/download', async (req, res) => {
    try {
        const { assetId, robloxCookie, placeId } = req.body;

        // Validate input
        if (!assetId) {
            return res.status(400).json({
                success: false,
                error: 'Asset ID is required'
            });
        }

        if (!assetId.match(/^\d+$/)) {
            return res.status(400).json({
                success: false,
                error: 'Asset ID must be numeric'
            });
        }

        console.log(`Processing asset ${assetId}`);

        // Get asset info first
        const assetInfo = await getAssetInfo(assetId, robloxCookie);
        if (!assetInfo) {
            return res.status(404).json({
                success: false,
                error: 'Asset not found or is private'
            });
        }

        // Try to download the asset
        const downloadResult = await downloadAsset(assetId, assetInfo.assetType, robloxCookie, placeId);
        
        if (downloadResult.success) {
            res.json({
                success: true,
                assetId: assetId,
                assetType: assetInfo.assetType,
                assetName: assetInfo.name,
                downloadUrl: downloadResult.downloadUrl,
                filename: downloadResult.filename,
                message: `Successfully processed ${assetInfo.assetType}`
            });
        } else {
            res.status(500).json({
                success: false,
                error: downloadResult.error
            });
        }

    } catch (error) {
        console.error('Download error:', error);
        res.status(500).json({
            success: false,
            error: 'Internal server error: ' + error.message
        });
    }
});

// Asset info helper function
async function getAssetInfo(assetId, cookie = null) {
    try {
        const headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        };

        if (cookie) {
            headers['Cookie'] = `.ROBLOSECURITY=${cookie}`;
        }

        // Try catalog API first
        const catalogResponse = await axios.get(
            `https://catalog.roblox.com/v1/catalog/items/details?itemIds=${assetId}`,
            { headers, timeout: 10000 }
        );

        if (catalogResponse.data && catalogResponse.data.data && catalogResponse.data.data.length > 0) {
            const item = catalogResponse.data.data[0];
            return {
                name: item.name,
                assetType: getAssetTypeFromId(item.itemType),
                creator: item.creatorName
            };
        }

        // Fallback to asset delivery API
        const assetResponse = await axios.get(
            `https://assetdelivery.roblox.com/v1/assetId/${assetId}`,
            { headers, timeout: 10000 }
        );

        if (assetResponse.status === 200) {
            return {
                name: `Asset_${assetId}`,
                assetType: 'unknown',
                creator: 'Unknown'
            };
        }

        return null;
    } catch (error) {
        console.error(`Failed to get asset info for ${assetId}:`, error.message);
        return null;
    }
}

// Asset type mapping
function getAssetTypeFromId(itemType) {
    const typeMap = {
        1: 'image',
        2: 'tshirt',
        3: 'audio',
        4: 'mesh',
        5: 'lua',
        8: 'hat',
        9: 'place',
        10: 'model',
        11: 'shirt',
        12: 'pants',
        13: 'decal',
        16: 'avatar',
        17: 'head',
        18: 'face',
        19: 'gear',
        21: 'badge',
        22: 'group_emblem',
        24: 'animation',
        25: 'arms',
        26: 'legs',
        27: 'torso',
        28: 'right_arm',
        29: 'left_arm',
        30: 'left_leg',
        31: 'right_leg',
        32: 'package',
        33: 'youtubed_video',
        34: 'game_pass',
        35: 'app',
        37: 'code',
        38: 'plugin',
        39: 'sponsored_ad',
        40: 'emoticon',
        41: 'video',
        42: 'tshirt_accessory',
        43: 'shirt_accessory',
        44: 'pants_accessory',
        45: 'jacket_accessory',
        46: 'sweater_accessory',
        47: 'shorts_accessory',
        48: 'left_shoe_accessory',
        49: 'right_shoe_accessory',
        50: 'dress_skirt_accessory'
    };
    
    return typeMap[itemType] || 'unknown';
}

// Download asset function
async function downloadAsset(assetId, assetType, cookie = null, placeId = null) {
    try {
        const headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        };

        if (cookie) {
            headers['Cookie'] = `.ROBLOSECURITY=${cookie}`;
        }

        let downloadUrl;
        let filename;

        // Determine download URL based on asset type
        if (assetType === 'audio' || assetType === 'sound') {
            downloadUrl = `https://assetdelivery.roblox.com/v1/asset?id=${assetId}`;
            filename = `sound_${assetId}.mp3`;
        } else if (assetType === 'animation') {
            downloadUrl = `https://assetdelivery.roblox.com/v1/asset?id=${assetId}`;
            filename = `animation_${assetId}.rbxm`;
        } else if (assetType === 'model' || assetType === 'place') {
            if (placeId) {
                downloadUrl = `https://assetdelivery.roblox.com/v1/asset?id=${placeId}&serverplaceid=${assetId}`;
            } else {
                downloadUrl = `https://assetdelivery.roblox.com/v1/asset?id=${assetId}`;
            }
            filename = `model_${assetId}.rbxm`;
        } else {
            // Default fallback
            downloadUrl = `https://assetdelivery.roblox.com/v1/asset?id=${assetId}`;
            filename = `asset_${assetId}.rbxm`;
        }

        // Test if the download URL works
        const testResponse = await axios.head(downloadUrl, { 
            headers, 
            timeout: 10000,
            maxRedirects: 5
        });

        if (testResponse.status === 200) {
            return {
                success: true,
                downloadUrl: downloadUrl,
                filename: filename
            };
        } else {
            throw new Error(`Asset not accessible: HTTP ${testResponse.status}`);
        }

    } catch (error) {
        console.error(`Download error for asset ${assetId}:`, error.message);
        return {
            success: false,
            error: `Failed to download asset: ${error.message}`
        };
    }
}

// Error handling middleware
app.use((error, req, res, next) => {
    console.error('Unhandled error:', error);
    res.status(500).json({
        success: false,
        error: 'Internal server error'
    });
});

// 404 handler for undefined routes
app.use('*', (req, res) => {
    res.status(404).json({
        success: false,
        error: 'Endpoint not found',
        path: req.originalUrl,
        availableEndpoints: [
            'GET /',
            'GET /api/health', 
            'POST /api/download'
        ]
    });
});

app.listen(PORT, () => {
    console.log(`🚀 Roblox Asset API server running on port ${PORT}`);
    console.log(`📋 Health check: http://localhost:${PORT}/api/health`);
    console.log(`📥 Download endpoint: http://localhost:${PORT}/api/download`);
});

const express = require('express');
const cors = require('cors');
const axios = require('axios');
const xml2js = require('xml2js');
const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');

const app = express();
const PORT = process.env.PORT || 3000;
const parser = new xml2js.Parser({ attrkey: "ATTR" });

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('downloads'));

// Create downloads directory if it doesn't exist
const DOWNLOADS_DIR = path.join(__dirname, 'downloads');
(async () => {
  try {
    await fs.access(DOWNLOADS_DIR);
  } catch {
    await fs.mkdir(DOWNLOADS_DIR, { recursive: true });
  }
})();

// Utility function to determine asset type
function getAssetType(xmlContent) {
  if (xmlContent.includes('Animation') || xmlContent.includes('KeyframeSequence')) {
    return 'animation';
  }
  if (xmlContent.includes('Sound') || xmlContent.includes('SoundId')) {
    return 'sound';
  }
  if (xmlContent.includes('Model') || xmlContent.includes('Part')) {
    return 'model';
  }
  return 'unknown';
}

// Utility function to generate filename
function generateFilename(assetId, assetType, extension = '.rbxm') {
  return `${assetType}_${assetId}_${Date.now()}${extension}`;
}

// Main asset download endpoint
app.post('/api/download', async (req, res) => {
  const { assetId, robloxCookie, placeId } = req.body;

  if (!assetId) {
    return res.status(400).json({ 
      success: false, 
      error: 'Asset ID is required' 
    });
  }

  try {
    console.log(`Downloading asset ${assetId}...`);
    
    // Prepare headers for public access
    const publicHeaders = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    };

    // Add cookie if provided
    const headers = { ...publicHeaders };
    if (robloxCookie) {
      headers['Cookie'] = `.ROBLOSECURITY=${robloxCookie}`;
    }

    // Try multiple CDN endpoints
    const cdnEndpoints = [
      `https://assetdelivery.roblox.com/v1/asset/?id=${assetId}`,
      `https://www.roblox.com/asset/?id=${assetId}`,
      `https://assetgame.roblox.com/asset/?id=${assetId}`
    ];

    let assetData = null;
    let usedEndpoint = null;

    // Try each endpoint until one works
    for (const endpoint of cdnEndpoints) {
      try {
        console.log(`Trying endpoint: ${endpoint}`);
        const response = await axios.get(endpoint, { 
          headers,
          timeout: 10000,
          maxRedirects: 5
        });

        if (response.data && response.data.length > 0) {
          assetData = response.data;
          usedEndpoint = endpoint;
          console.log(`Success with endpoint: ${endpoint}`);
          break;
        }
      } catch (error) {
        console.log(`Failed with endpoint ${endpoint}:`, error.message);
        continue;
      }
    }

    if (!assetData) {
      return res.status(404).json({
        success: false,
        error: 'Asset not found or not accessible'
      });
    }

    // Determine asset type
    const assetType = getAssetType(assetData);
    console.log(`Detected asset type: ${assetType}`);

    // Filter for animations and sounds only
    if (assetType !== 'animation' && assetType !== 'sound') {
      return res.status(400).json({
        success: false,
        error: `Asset type '${assetType}' is not supported. Only animations and sounds are allowed.`
      });
    }

    // Generate filename and save asset
    const filename = generateFilename(assetId, assetType);
    const filePath = path.join(DOWNLOADS_DIR, filename);
    
    await fs.writeFile(filePath, assetData, 'utf8');

    // Parse XML to get additional metadata
    let metadata = {};
    try {
      const xmlResult = await parser.parseString(assetData);
      if (xmlResult && xmlResult.roblox) {
        metadata = {
          name: xmlResult.roblox.Item?.[0]?.Properties?.[0]?.string?.find(s => s.ATTR?.name === 'Name')?._,
          creator: xmlResult.roblox.Item?.[0]?.Properties?.[0]?.string?.find(s => s.ATTR?.name === 'CreatorName')?._,
          assetType: xmlResult.roblox.Item?.[0].ATTR?.class
        };
      }
    } catch (xmlError) {
      console.log('XML parsing failed:', xmlError.message);
    }

    console.log(`Asset ${assetId} downloaded successfully as ${filename}`);

    res.json({
      success: true,
      assetId,
      assetType,
      filename,
      downloadUrl: `${req.protocol}://${req.get('host')}/${filename}`,
      metadata,
      usedEndpoint
    });

  } catch (error) {
    console.error('Download error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to download asset',
      details: error.message
    });
  }
});

// Endpoint to get asset info without downloading
app.get('/api/info/:assetId', async (req, res) => {
  const { assetId } = req.params;
  const { robloxCookie } = req.query;

  try {
    const headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    };

    if (robloxCookie) {
      headers['Cookie'] = `.ROBLOSECURITY=${robloxCookie}`;
    }

    // Get asset info from Roblox API
    const apiResponse = await axios.get(`https://api.roblox.com/marketplace/productinfo?assetId=${assetId}`, {
      headers,
      timeout: 5000
    });

    const productInfo = apiResponse.data;

    // Check if it's animation or sound
    const allowedTypes = [
      'Animation', 'Sound', 'Audio'  // Roblox asset type names
    ];

    if (!allowedTypes.some(type => 
      productInfo.AssetTypeId === getAssetTypeId(type) || 
      productInfo.Name?.toLowerCase().includes(type.toLowerCase())
    )) {
      return res.status(400).json({
        success: false,
        error: 'Asset is not an animation or sound'
      });
    }

    res.json({
      success: true,
      assetInfo: {
        id: productInfo.AssetId,
        name: productInfo.Name,
        description: productInfo.Description,
        creator: productInfo.Creator?.Name,
        assetType: productInfo.AssetTypeId,
        isForSale: productInfo.IsForSale,
        price: productInfo.PriceInRobux,
        created: productInfo.Created,
        updated: productInfo.Updated
      }
    });

  } catch (error) {
    console.error('Info retrieval error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get asset info',
      details: error.message
    });
  }
});

// Helper function for asset type IDs
function getAssetTypeId(typeName) {
  const typeMap = {
    'Animation': 24,
    'Sound': 3,
    'Audio': 3
  };
  return typeMap[typeName];
}

// Batch download endpoint
app.post('/api/batch-download', async (req, res) => {
  const { assetIds, robloxCookie, placeId } = req.body;

  if (!assetIds || !Array.isArray(assetIds) || assetIds.length === 0) {
    return res.status(400).json({
      success: false,
      error: 'Asset IDs array is required'
    });
  }

  if (assetIds.length > 10) {
    return res.status(400).json({
      success: false,
      error: 'Maximum 10 assets per batch request'
    });
  }

  const results = [];

  for (const assetId of assetIds) {
    try {
      // Reuse the download logic from the single download endpoint
      const downloadResult = await downloadSingleAsset(assetId, robloxCookie, placeId, req);
      results.push({
        assetId,
        success: true,
        ...downloadResult
      });
    } catch (error) {
      results.push({
        assetId,
        success: false,
        error: error.message
      });
    }
  }

  res.json({
    success: true,
    results
  });
});

// Helper function for single asset download (extracted from main endpoint)
async function downloadSingleAsset(assetId, robloxCookie, placeId, req) {
  const headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
  };

  if (robloxCookie) {
    headers['Cookie'] = `.ROBLOSECURITY=${robloxCookie}`;
  }

  const cdnEndpoints = [
    `https://assetdelivery.roblox.com/v1/asset/?id=${assetId}`,
    `https://www.roblox.com/asset/?id=${assetId}`,
    `https://assetgame.roblox.com/asset/?id=${assetId}`
  ];

  let assetData = null;
  let usedEndpoint = null;

  for (const endpoint of cdnEndpoints) {
    try {
      const response = await axios.get(endpoint, { 
        headers,
        timeout: 10000,
        maxRedirects: 5
      });

      if (response.data && response.data.length > 0) {
        assetData = response.data;
        usedEndpoint = endpoint;
        break;
      }
    } catch (error) {
      continue;
    }
  }

  if (!assetData) {
    throw new Error('Asset not found or not accessible');
  }

  const assetType = getAssetType(assetData);

  if (assetType !== 'animation' && assetType !== 'sound') {
    throw new Error(`Asset type '${assetType}' is not supported`);
  }

  const filename = generateFilename(assetId, assetType);
  const filePath = path.join(DOWNLOADS_DIR, filename);
  
  await fs.writeFile(filePath, assetData, 'utf8');

  let metadata = {};
  try {
    const xmlResult = await parser.parseString(assetData);
    if (xmlResult && xmlResult.roblox) {
      metadata = {
        name: xmlResult.roblox.Item?.[0]?.Properties?.[0]?.string?.find(s => s.ATTR?.name === 'Name')?._,
        creator: xmlResult.roblox.Item?.[0]?.Properties?.[0]?.string?.find(s => s.ATTR?.name === 'CreatorName')?._,
        assetType: xmlResult.roblox.Item?.[0].ATTR?.class
      };
    }
  } catch (xmlError) {
    // Ignore XML parsing errors for batch operations
  }

  return {
    assetType,
    filename,
    downloadUrl: `${req.protocol}://${req.get('host')}/${filename}`,
    metadata,
    usedEndpoint
  };
}

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    success: true, 
    message: 'Roblox Asset Downloader API is running',
    timestamp: new Date().toISOString()
  });
});

// List downloaded files endpoint
app.get('/api/files', async (req, res) => {
  try {
    const files = await fs.readdir(DOWNLOADS_DIR);
    const fileList = files
      .filter(file => file.endsWith('.rbxm'))
      .map(file => ({
        filename: file,
        downloadUrl: `${req.protocol}://${req.get('host')}/${file}`
      }));

    res.json({
      success: true,
      files: fileList
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to list files'
    });
  }
});

// Delete file endpoint
app.delete('/api/files/:filename', async (req, res) => {
  const { filename } = req.params;
  
  try {
    const filePath = path.join(DOWNLOADS_DIR, filename);
    await fs.unlink(filePath);
    
    res.json({
      success: true,
      message: 'File deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to delete file'
    });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({
    success: false,
    error: 'Internal server error'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`Roblox Asset Downloader API running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/api/health`);
});

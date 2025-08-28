# Roblox Asset Downloader API

A Node.js API for downloading Roblox animations and sounds as .rbxm files that can be loaded directly into Roblox Studio via a plugin.

## Features

- Download Roblox animations and sounds
- Supports both public and private assets (with Roblox cookie)
- Returns .rbxm files compatible with Roblox Studio
- Batch download multiple assets
- RESTful API with JSON responses
- Compatible with Roblox plugins via HTTP requests

## Quick Start

### Local Development

1. Clone this repository:
```bash
git clone https://github.com/nowyhub/AssetDownloader.git
cd roblox-asset-downloader-api
```

2. Install dependencies:
```bash
npm install
```

3. Start the server:
```bash
npm start
```

4. Test the API:
```bash
curl http://localhost:3000/api/health
```

### Deploy to Render

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

1. Fork this repository
2. Connect your GitHub account to Render
3. Create a new Web Service
4. Connect your forked repository
5. Use these settings:
   - **Environment**: Node
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Port**: 3000

## API Endpoints

### Health Check
```bash
GET /api/health
```

### Download Single Asset
```bash
POST /api/download
Content-Type: application/json

{
  "assetId": "507766388",
  "robloxCookie": "optional_cookie_for_private_assets",
  "placeId": "optional_place_id"
}
```

### Get Asset Info
```bash
GET /api/info/:assetId
```

### Batch Download
```bash
POST /api/batch-download
Content-Type: application/json

{
  "assetIds": ["507766388", "180426354", "182393478"]
}
```

### List Downloaded Files
```bash
GET /api/files
```

## Example Asset IDs for Testing

- `507766388` - Default dance animation
- `180426354` - Running animation
- `182393478` - Climbing animation
- `131961136` - Sound effect

## Usage with Roblox Plugin

This API is designed to work with a Roblox Studio plugin. The plugin can:

1. Send HTTP requests to download assets
2. Receive .rbxm file URLs
3. Load the assets directly into the workspace

## Environment Variables

- `PORT` - Server port (default: 3000)

## License

MIT License

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Support

For issues and questions, please open a GitHub issue.

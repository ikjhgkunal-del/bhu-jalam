#!/bin/bash

echo "🔄 Rebuilding Flutter web app..."
flutter build web

echo "📁 Copying build to deploy directory..."
rm -rf deploy/*
cp -r build/web/* deploy/

echo "📤 Committing and pushing to git..."
cd deploy
git add .
git commit -m "Update deployment - $(date)"
git push origin main

echo "✅ Deployment updated! Check your Vercel dashboard."

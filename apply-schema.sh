#!/bin/bash
# ONE-CLICK DATABASE SCHEMA APPLICATION
# Run this on your local machine with Supabase CLI installed

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  CRAV NEWS COMPARE - ONE-CLICK SCHEMA APPLICATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found!"
    echo ""
    echo "📥 Install it with:"
    echo "   npm install -g supabase"
    echo "   OR"
    echo "   brew install supabase/tap/supabase"
    echo ""
    exit 1
fi

echo "✅ Supabase CLI found"
echo ""

# Project details
PROJECT_REF="kteobfyferrukqeolofj"
DB_PASSWORD="oce@N251812345"

echo "📦 Project: $PROJECT_REF"
echo ""

# Download schema if not present
if [ ! -f "database/schema.sql" ]; then
    echo "📥 Downloading schema from GitHub..."
    mkdir -p database
    curl -s -o database/schema.sql \
        https://raw.githubusercontent.com/CR-AudioViz-AI/crav-news-compare/main/database/schema.sql
    echo "✅ Schema downloaded"
else
    echo "✅ Schema file found locally"
fi

echo ""
echo "🔑 Connecting to Supabase..."
echo ""

# Link to project
supabase link --project-ref $PROJECT_REF

# Apply schema
echo ""
echo "🚀 Applying schema..."
echo ""

PGPASSWORD=$DB_PASSWORD supabase db push

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ SCHEMA APPLICATION COMPLETE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔍 Verify with:"
echo "   supabase db diff"
echo ""
echo "🌐 Test app at:"
echo "   https://crav-news-compare-quvy77mmj-roy-hendersons-projects-1d3d5e94.vercel.app"
echo ""

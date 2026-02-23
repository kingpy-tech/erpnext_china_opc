#!/bin/bash
echo "Installing MkDocs dependencies..."
python3 -m pip install -r requirements.txt
echo "Building MkDocs site..."
python3 -m mkdocs build

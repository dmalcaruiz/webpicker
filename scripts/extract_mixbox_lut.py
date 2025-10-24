#!/usr/bin/env python3
"""
Extracts Mixbox LUT data from JavaScript and converts to Dart format.

This script:
1. Reads the compressed LUT from mixbox.esm.js
2. Uses Node.js to decompress it (easier than reimplementing in Python)
3. Converts to Dart List<int> format
4. Generates mixbox_lut_data.dart
"""

import subprocess
import os
import sys

def create_extraction_script():
    """Create a temporary Node.js script to decompress the LUT"""
    js_script = """
const fs = require('fs');
const path = require('path');

// Read the mixbox module
const mixboxPath = path.join(__dirname, '../reference-mixbox/mixbox-master/javascript/mixbox.esm.js');
const mixboxCode = fs.readFileSync(mixboxPath, 'utf8');

// Extract the compressed LUT string (it's the large string at the end)
// Find the var lut = decompress("...") line
const lutMatch = mixboxCode.match(/var lut = decompress\\("([^"]+)"\\);/);

if (!lutMatch) {
    console.error('Could not find LUT data in mixbox.esm.js');
    process.exit(1);
}

const compressedLut = lutMatch[1];
console.log('Found compressed LUT, length:', compressedLut.length);

// We need to extract and run the decompress function
// Find the decompress function and all its dependencies
const decompressFunctionStart = mixboxCode.indexOf('function decompress(');
const decompressFunctionEnd = mixboxCode.indexOf('var lut = decompress');

if (decompressFunctionStart === -1) {
    console.error('Could not find decompress function');
    process.exit(1);
}

// Extract all the decompression-related code
const decompressionCode = mixboxCode.substring(decompressFunctionStart, decompressFunctionEnd);

// Execute the decompression
eval(decompressionCode);
const lut = decompress(compressedLut);

console.log('Decompressed LUT, length:', lut.length);
console.log('Expected length: 786432 (64*64*64*3)');

// The LUT should be 786432 bytes (64*64*64*3)
// Skip any header if the decompressed data is larger
const expectedSize = 786432;
let lutBuffer;

if (lut.length === expectedSize) {
    lutBuffer = Buffer.from(lut);
} else if (lut.length > expectedSize) {
    console.log('Decompressed data larger than expected, finding actual LUT data...');
    // The actual LUT data is at the end
    const offset = lut.length - expectedSize;
    console.log('Skipping', offset, 'bytes of header/metadata');
    lutBuffer = Buffer.from(lut.slice(offset));
} else {
    console.error('Decompressed data smaller than expected!');
    process.exit(1);
}

fs.writeFileSync('mixbox_lut_raw.bin', lutBuffer);
console.log('Written raw LUT to mixbox_lut_raw.bin (' + lutBuffer.length + ' bytes)');
"""

    with open('extract_lut.js', 'w') as f:
        f.write(js_script)

def run_extraction():
    """Run the Node.js extraction script"""
    print("Running Node.js extraction script...")
    try:
        result = subprocess.run(['node', 'extract_lut.js'],
                              capture_output=True,
                              text=True,
                              check=True)
        print(result.stdout)
        if result.stderr:
            print("Warnings:", result.stderr, file=sys.stderr)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error running extraction script: {e}", file=sys.stderr)
        print("stdout:", e.stdout, file=sys.stderr)
        print("stderr:", e.stderr, file=sys.stderr)
        return False
    except FileNotFoundError:
        print("Error: Node.js not found. Please install Node.js to run this script.", file=sys.stderr)
        return False

def convert_to_dart():
    """Convert the raw binary LUT to Dart format"""
    print("Converting to Dart format...")

    # Read the raw binary data
    with open('mixbox_lut_raw.bin', 'rb') as f:
        lut_data = f.read()

    print(f"Read {len(lut_data)} bytes")

    # Generate Dart file
    dart_code = """// ==========================================================
//  MIXBOX 2.0 LUT DATA
//  Automatically generated from mixbox.esm.js
//
//  This file contains the lookup table for Mixbox pigment mixing.
//  Original implementation: (c) 2022 Secret Weapons
//  License: Creative Commons Attribution-NonCommercial 4.0
// ==========================================================

/// Mixbox Lookup Table (LUT) Data
///
/// This is a 64×64×64 lookup table that maps RGB colors to a
/// 7-dimensional latent space representing pigment mixing behavior.
///
/// Size: 786,432 bytes (64 * 64 * 64 * 3)
const List<int> mixboxLutData = [
"""

    # Write data in chunks of 16 bytes per line for readability
    for i in range(0, len(lut_data), 16):
        chunk = lut_data[i:i+16]
        line = "  " + ", ".join(str(b) for b in chunk)
        if i + 16 < len(lut_data):
            line += ","
        dart_code += line + "\n"

    dart_code += "];\n"

    # Write to output file with UTF-8 encoding
    output_path = os.path.join('..', 'lib', 'utils', 'mixbox_lut_data.dart')
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(dart_code)

    print(f"Generated {output_path}")
    print(f"File size: {len(dart_code)} bytes")

def cleanup():
    """Remove temporary files"""
    for filename in ['extract_lut.js', 'mixbox_lut_raw.bin']:
        if os.path.exists(filename):
            os.remove(filename)
            print(f"Cleaned up {filename}")

def main():
    print("=" * 60)
    print("Mixbox LUT Extraction Script")
    print("=" * 60)
    print()

    # Change to scripts directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)

    try:
        # Step 1: Create extraction script
        print("Step 1: Creating Node.js extraction script...")
        create_extraction_script()
        print("[OK] Created extract_lut.js")
        print()

        # Step 2: Run extraction
        print("Step 2: Extracting LUT from mixbox.esm.js...")
        if not run_extraction():
            print("[FAIL] Extraction failed")
            return 1
        print("[OK] Extraction complete")
        print()

        # Step 3: Convert to Dart
        print("Step 3: Converting to Dart format...")
        convert_to_dart()
        print("[OK] Dart file generated")
        print()

        # Step 4: Cleanup
        print("Step 4: Cleaning up temporary files...")
        cleanup()
        print("[OK] Cleanup complete")
        print()

        print("=" * 60)
        print("SUCCESS! Mixbox LUT has been extracted and converted.")
        print("Output: lib/utils/mixbox_lut_data.dart")
        print("=" * 60)
        return 0

    except Exception as e:
        print(f"\n[ERROR] {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())

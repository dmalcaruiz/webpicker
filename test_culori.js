// Test script to verify expected values from Culori
// Run with: node test_culori.js

import { formatRgb, converter } from './reference-culori/src/index.js';

const oklchToRgb = converter('oklch');

console.log('=== Test Case 1: Mid-blue (L=0.7, C=0.15, H=240) ===');
const color1 = oklchToRgb({ mode: 'oklch', l: 0.7, c: 0.15, h: 240 });
console.log('Result:', color1);
console.log('RGB (0-255):', {
  r: Math.round(color1.r * 255),
  g: Math.round(color1.g * 255),
  b: Math.round(color1.b * 255)
});

console.log('\n=== Test Case 2: Pure red (L=0.6, C=0.25, H=0) ===');
const color2 = oklchToRgb({ mode: 'oklch', l: 0.6, c: 0.25, h: 0 });
console.log('Result:', color2);
console.log('RGB (0-255):', {
  r: Math.round(color2.r * 255),
  g: Math.round(color2.g * 255),
  b: Math.round(color2.b * 255)
});

console.log('\n=== Test Case 3: Pure green (L=0.7, C=0.2, H=120) ===');
const color3 = oklchToRgb({ mode: 'oklch', l: 0.7, c: 0.2, h: 120 });
console.log('Result:', color3);
console.log('RGB (0-255):', {
  r: Math.round(color3.r * 255),
  g: Math.round(color3.g * 255),
  b: Math.round(color3.b * 255)
});

console.log('\n=== Test Case 4: Light color (L=0.8, C=0.05, H=60) ===');
const color4 = oklchToRgb({ mode: 'oklch', l: 0.8, c: 0.05, h: 60 });
console.log('Result:', color4);
console.log('RGB (0-255):', {
  r: Math.round(color4.r * 255),
  g: Math.round(color4.g * 255),
  b: Math.round(color4.b * 255)
});

console.log('\n=== Test Case 5: Cyan test (L=0.5, C=0.1, H=180) ===');
const color5 = oklchToRgb({ mode: 'oklch', l: 0.5, c: 0.1, h: 180 });
console.log('Result:', color5);
console.log('RGB (0-255):', {
  r: Math.round(color5.r * 255),
  g: Math.round(color5.g * 255),
  b: Math.round(color5.b * 255)
});


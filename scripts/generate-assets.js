const fs = require('fs');
const path = require('path');

function writeBmp(file, width, height, colorFn) {
  const rowSize = Math.ceil((width * 3) / 4) * 4;
  const pixelDataSize = rowSize * height;
  const fileSize = 54 + pixelDataSize;

  const buf = Buffer.alloc(fileSize);

  buf.write('BM', 0);
  buf.writeUInt32LE(fileSize, 2);
  buf.writeUInt32LE(0, 6);
  buf.writeUInt32LE(54, 10);

  buf.writeUInt32LE(40, 14);
  buf.writeInt32LE(width, 18);
  buf.writeInt32LE(height, 22);
  buf.writeUInt16LE(1, 26);
  buf.writeUInt16LE(24, 28);
  buf.writeUInt32LE(0, 30);
  buf.writeUInt32LE(pixelDataSize, 34);
  buf.writeInt32LE(2835, 38);
  buf.writeInt32LE(2835, 42);
  buf.writeUInt32LE(0, 46);
  buf.writeUInt32LE(0, 50);

  for (let y = 0; y < height; y++) {
    const rowOffset = 54 + (height - 1 - y) * rowSize;
    for (let x = 0; x < width; x++) {
      const c = colorFn(x, y);
      const o = rowOffset + x * 3;
      buf[o] = c[2];     // B
      buf[o + 1] = c[1]; // G
      buf[o + 2] = c[0]; // R
    }
  }

  fs.writeFileSync(file, buf);
}

const top = [139, 92, 246];
const bottom = [6, 182, 212];

const colorFn = (x, y) => {
  const t = y / 310;
  return [
    Math.round(top[0] + (bottom[0] - top[0]) * t),
    Math.round(top[1] + (bottom[1] - top[1]) * t),
    Math.round(top[2] + (bottom[2] - top[2]) * t),
  ];
};

const buildDir = path.join(__dirname, '..', 'build');
if (!fs.existsSync(buildDir)) fs.mkdirSync(buildDir, { recursive: true });

writeBmp(path.join(buildDir, 'installerSidebar.bmp'), 164, 311, colorFn);
writeBmp(path.join(buildDir, 'uninstallerSidebar.bmp'), 164, 311, colorFn);

console.log('Installer sidebars generated.');

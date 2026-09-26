#!/usr/bin/env python3
"""Convert a UF2 file to Intel HEX format."""
import struct, sys

def uf2_to_hex(uf2_path, hex_path):
    blocks = []
    with open(uf2_path, 'rb') as f:
        while True:
            block = f.read(512)
            if len(block) < 512:
                break
            magic1, magic2, flags, addr, size = struct.unpack_from('<IIIII', block)
            if magic1 != 0x0A324655 or magic2 != 0x9E5D5157:
                continue
            data = block[32:32+size]
            blocks.append((addr, data))

    blocks.sort(key=lambda b: b[0])

    with open(hex_path, 'w') as out:
        prev_upper = None
        for addr, data in blocks:
            offset = 0
            while offset < len(data):
                full_addr = addr + offset
                upper = (full_addr >> 16) & 0xFFFF
                if upper != prev_upper:
                    record = bytes([0x02, 0x00, 0x00, 0x04, upper >> 8, upper & 0xFF])
                    checksum = (~sum(record) + 1) & 0xFF
                    out.write(f':{record.hex().upper()}{checksum:02X}\n')
                    prev_upper = upper
                chunk = min(16, len(data) - offset)
                line_addr = full_addr & 0xFFFF
                record = bytes([chunk, line_addr >> 8, line_addr & 0xFF, 0x00]) + data[offset:offset+chunk]
                checksum = (~sum(record) + 1) & 0xFF
                out.write(f':{record.hex().upper()}{checksum:02X}\n')
                offset += chunk

        out.write(':00000001FF\n')

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f'Usage: {sys.argv[0]} <input.uf2> <output.hex>')
        sys.exit(1)
    uf2_to_hex(sys.argv[1], sys.argv[2])
    print(f'Converted {sys.argv[1]} -> {sys.argv[2]}')

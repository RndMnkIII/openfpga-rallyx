# Library

## Filesystem Folder Location

Library images are stored in the `/System/Library/Images/<platform>/` directory on the SD Card, where `<platform>`is the lowercase shortname of the platform the images have been created for.

## Filename Generation

A single asset's CRC32 (lowercase only) directly becomes the image filename: `02468ace.bin`

If multiple assets are used, all assets' binary files shall be concatenated in alphabetical order and the CRC32 of the entire resulting blob is taken, as above.

If multiple assets are contained within subfolders, all assets' binary files shall be concatenated in alphabetical order within each directory, starting in the deepest subfolder and recursively traversing the folder structure alphabetically outwards.

### Example

```
Folder/B/Sample/1.bin+2.bin+
Folder/B/3.bin+4.bin+
Folder/D/C/5.bin+6.bin+
Folder/D/7.bin+8.bin+
Folder/9.bin
```

> Note that simply using a previous CRC32's as the starting value for the next block can be used instead of concatenating all files. Both methods give the same result, as long as the same order is followed.

## Image Format

Library images have an 8 byte header:

#### Magic (4 byte)

32 bit (Little Endian) format: `0x41504910` = RGB 16 bit or `0x41504920` = RGB 32 bit

#### Width (2 byte)

16 bit (Little Endian) image width in pixels

#### Height (2 byte)

16 bit (Little Endian) image height in pixels

Library images contain the RGB pixel data (rotated by 90 degrees anti-clockwise) after the header:

#### RGB 16 bit Format

Not currently used

#### RGB 32 bit Format

**BGRA** (Big Endian) 1 pixel byte order: `0xBB`, `0xGG`, `0xRR`, `0xAA`

Set the **Alpha** color channel of each pixel to `0xFF/255` so the image is fully opaque

(8 bit color channels: **B** = Blue, **G** = Green, **R** = Red, **A** = Alpha)

### Sample Code

```python
import sys
import struct
import PIL
from PIL import Image, ImageOps
from pathlib import Path

def main(argv=None):
    print("Image Converter v1.0")
    if len(sys.argv) == 2: # Print Error If Not Enough Arguments Given
        print("Error: Output file not specified")
        print("Usage: image_converter [image_in] [file_out]")
        print("Supported images: BLP, BMP, DDS, DIB, EPS, GIF, ICNS, ICO, IM, JPEG, JPEG 2000,")
        print("                  MSP, PCX, PNG, PPM, SGI, SPIDER, TGA, TIFF, WebP and XBM")
        sys.exit()
    if len(sys.argv) >= 4: # Print Error If Too Many Arguments Given
        print("Error: Too many arguments specified")
        print("Usage: image_converter [image_in] [file_out]")
        print("Supported images: BLP, BMP, DDS, DIB, EPS, GIF, ICNS, ICO, IM, JPEG, JPEG 2000,")
        print("                  MSP, PCX, PNG, PPM, SGI, SPIDER, TGA, TIFF, WebP and XBM")
        sys.exit()
    if len(sys.argv) == 1: # Print Usage If No Arguments Given
        print("Usage: image_converter [image_in] [file_out]")
        print("Supported images: BLP, BMP, DDS, DIB, EPS, GIF, ICNS, ICO, IM, JPEG, JPEG 2000,")
        print("                  MSP, PCX, PNG, PPM, SGI, SPIDER, TGA, TIFF, WebP and XBM")
    else: # Convert Image
        if argv is None: argv = sys.argv[1:]
        infilename, outfilename = argv
        in_file = Path(infilename)

        if in_file.is_file(): # Input File Exists
            in_img = PIL.Image.open(infilename)
            out_img = open(outfilename, 'wb')
            width, height = in_img.size
            bpp = 4
            print("Image: Name   =", infilename)
            print("Image: BPP    =", bpp*8)
            print("Image: Width  =", width)
            print("Image: Height =", height)
            print("Saving Image...")

            # PASS 1: Convert Image To RGBA
            rgb_img = in_img.convert("RGBA")
            #rgb_img.show()

            # PASS 2: Rotate Image 90 Degrees Anti-Clockwise
            out = rgb_img.rotate(90, expand=True)
            #out.show()

            # PASS 3: Convert Image Data To 32-bit $BGRA Binary Data
            pixels = out.getdata()
            image = []
            image.append(bpp*8) # Header Magic (32-bit)
            image.append(0x49)
            image.append(0x50)
            image.append(0x41)
            image.append(width&0xFF) # Header Width (16-bit)
            image.append((width>>8)&0xFF)
            image.append(height&0xFF) # Header Height (16-bit)
            image.append((height>>8)&0xFF)
            for i in range(width*height):
                image.append(pixels[i][2]) # Blue Byte
                image.append(pixels[i][1]) # Green Byte
                image.append(pixels[i][0]) # Red Byte
                image.append(pixels[i][3]) # Alpha Byte
            for i in range((width*height*bpp)+8): out_img.write(struct.pack('B', image[i])) # Write Header + Pixels
            out_img.close()
            print("Done")
        else: # Input File Does Not Exist
            print("Error: Couldn't open the file", infilename, "for input")
            print("Usage: image_converter [image_in] [file_out]")
            print("Supported images: BLP, BMP, DDS, DIB, EPS, GIF, ICNS, ICO, IM, JPEG, JPEG 2000,")
            print("                  MSP, PCX, PNG, PPM, SGI, SPIDER, TGA, TIFF, WebP and XBM")

if __name__ == '__main__':
    main()
```

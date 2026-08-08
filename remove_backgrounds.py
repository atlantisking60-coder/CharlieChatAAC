from PIL import Image
import os

# Input and output directories
input_dir = r"C:\Users\Craig\Downloads\Charlie Chat\assets\Default Tab Icons"
output_dir = os.path.join(input_dir, "Done")

# Create output directory if it doesn't exist
os.makedirs(output_dir, exist_ok=True)

# Get all PNG files in the input directory
image_files = [f for f in os.listdir(input_dir) if f.lower().endswith('.png')]

print(f"Found {len(image_files)} images to process")

for filename in image_files:
    input_path = os.path.join(input_dir, filename)
    output_path = os.path.join(output_dir, filename)
    
    try:
        # Open image
        img = Image.open(input_path)
        
        # Convert to RGBA if not already
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Get pixel data
        pixels = img.load()
        width, height = img.size
        
        # Process each pixel
        for y in range(height):
            for x in range(width):
                r, g, b, a = pixels[x, y]
                
                # Calculate brightness (simple average)
                brightness = (r + g + b) / 3
                
                # If pixel is not white (or near white), make it transparent
                # Threshold: keep pixels with brightness > 200 (close to white)
                if brightness < 200:
                    # This is a colored pixel - make it transparent
                    pixels[x, y] = (r, g, b, 0)
                else:
                    # This is white - keep it fully opaque
                    pixels[x, y] = (r, g, b, 255)
        
        # Save the result
        img.save(output_path, 'PNG')
        print(f"Processed: {filename}")
        
    except Exception as e:
        print(f"Error processing {filename}: {str(e)}")

print("Done! Check the 'Done' folder for processed images.")

import os

# Path to the directory containing the audio captcha files
audio_captcha_dir = "audio_captchas"

# Output file
output_file = "audio_captchas_list.txt"

# Collect file names without extensions
audio_files = [os.path.splitext(file)[0] for file in os.listdir(audio_captcha_dir) if os.path.isfile(os.path.join(audio_captcha_dir, file))]

# Write to the output file in the desired format
with open(output_file, "w") as f:
    f.write('local audioCaptchaFiles = {\n')
    for i, file in enumerate(audio_files):
        # Add comma after every filename except the last one
        line_end = ',' if i < len(audio_files) - 1 else ''
        f.write(f'    "{file}"{line_end}\n')
    f.write('}\n')

print(f"File '{output_file}' created with the list of audio captcha filenames.")

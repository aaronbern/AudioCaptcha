from gtts import gTTS
import os
import random

def generate_audio_captcha(output_dir, num_files=50, sequence_length=8):
    """
    Generates audio CAPTCHA sequences using gTTS and saves them as .wav files.
    Applies a very slow playback effect and introduces gaps between letters to make it more annoying.
    Increases the audio volume by 25%.

    :param output_dir: Directory to save the audio files.
    :param num_files: Number of CAPTCHA files to generate.
    :param sequence_length: Length of each CAPTCHA sequence.
    """
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Pool of characters/numbers to use in CAPTCHA
    pool = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", 
            "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", 
            "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", 
            "4", "5", "6", "7", "8", "9"]

    for i in range(num_files):
        sequence = [random.choice(pool) for _ in range(sequence_length)]
        sequence_str = "".join(sequence)  # E.g., "abc12"
        audio_output_path = os.path.join(output_dir, f"{sequence_str}.wav")

        # Generate TTS audio for the sequence
        spaced_sequence = " ".join(sequence)  # Add explicit spaces between letters
        tts = gTTS(text=spaced_sequence, lang="en", slow=True)
        temp_mp3_path = audio_output_path.replace(".wav", ".mp3")

        # Save as MP3 first
        tts.save(temp_mp3_path)

        # Apply a very slow playback effect and increase volume by 25%
        # The volume filter is set to 1.25 to make the audio 25% louder
        ffmpeg_command = (
            f"ffmpeg -i {temp_mp3_path} "
            f"-af \"volume=1.5,atempo=0.5,atempo=0.5\" "
            f"-ar 44100 -ac 2 {audio_output_path}"
        )
        os.system(ffmpeg_command)

        # Clean up the temporary MP3 file
        os.remove(temp_mp3_path)

        print(f"Generated with slow effect, increased volume, and explicit spacing: {audio_output_path}")

if __name__ == "__main__":
    output_directory = "./audio_captchas"
    num_files_to_generate = 50
    captcha_length = 8  # Length of each CAPTCHA sequence

    generate_audio_captcha(output_directory, num_files=num_files_to_generate, sequence_length=captcha_length)

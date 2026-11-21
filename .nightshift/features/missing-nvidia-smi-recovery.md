# Missing nvidia-smi recovery

Probe before agent launch, searching PATH and known NVIDIA driver installation locations. If the utility is missing or fails, launch with GPU information marked incomplete and let the agent diagnose discovery or driver problems, obtain explicit approval for any needed acquisition or installation, and rerun the hardware probe. Treat nvidia-smi as a driver component rather than an independent executable download; block workflows that need the missing facts until verified. Captured 2026-10-21.

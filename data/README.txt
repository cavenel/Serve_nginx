This folder is only used for local testing and by the GitHub Actions smoke
test, where it is mounted at /home/data. It is not copied into the image.

On SciLifeLab Serve the project volume is mounted at /home/data and served
from the root of the app URL, e.g.
https://<subdomain>.serve.scilifelab.se/<file>.

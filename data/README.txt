Put small, fixed datasets in this folder. They are copied into the container
image and served from the root of the app URL, e.g.
https://<subdomain>.serve.scilifelab.se/<file>.

For large data, leave this folder empty and mount the Serve project volume at
/home/serve/data instead (see the repository README).

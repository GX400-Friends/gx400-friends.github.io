DOCKER = docker run -it --rm \
	-p 4000:4000 \
	-v $$(pwd):/site \
	-v $$(pwd)/vendor:/usr/local/bundle/ \
  	bretfisher/jekyll-serve:stable-20230113194043

serve:
	$(DOCKER)

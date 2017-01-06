# Skema - Universal web app in nginx
The goal of this project is to create one-size-fits-all restful apps on postgresql and nginx. 

Mustache and postgresql modules are powerful by themselves, as they allow to declare endpoints, sql queries and html templates at the low level.  

**Skema** scaffolds all those magically, making it possible to build web apps by only declaring tables in database and following some simple conventions regarding foreign keys.

It adds a (precomputed) layer of introspection to resources (tables), so each request knows what kind of relations and methods make sense. It figures out which resources are nested into one another, how to fetch all related items in one go, how to build nav and display them in HTML meaningfully, how to validate, create, update  and delete them. Optional versioning and immutability.

The system provides and end-to-end lifecycle for your data, and is friendly to be extensible at scale. A web app with 10 REST resources and only 5 html files shared between different projects? It is possible.


## Installation
You will need to compile nginx with a bunch of modules. We provide a script that compiles nginx locally for the app (will not mess with nginx you may already have installed). You will only need one nginx compiled for multiple skema apps.


		
		# Make a folder
		mkdir konstruxi-nginx
		cd konstruxi-nginx
		
		# Main dependencies
		git clone https://github.com/nginx/nginx;
		git clone https://github.com/konstruxi/form-input-nginx-module;
		git clone https://github.com/konstruxi/ngx_postgres;
		git clone https://github.com/konstruxi/mustache-nginx-module;
		git clone https://github.com/openresty/nginx-eval-module.git;

		# Optional dependencies
		git clone https://github.com/openresty/echo-nginx-module.git;
		git clone https://github.com/simpl/ngx_devel_kit.git;
		git clone https://github.com/openresty/set-misc-nginx-module.git;
		git clone https://github.com/vkholodkov/nginx-upload-module.git;
		git clone https://github.com/masterzen/nginx-upload-progress-module.git;

		# Compile nginx (change path to your app)
		env APP_PATH=../../skema ../../skema/compile-nginx.sh


## Heroku

Use this buildpack to compile and run nginx in your heroku app. 

github.com/konstruxi/konstruxi-buildpack

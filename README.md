# VagrantChefEFK
Repository for various artifacts used to cobble together Packer, Vagrant, and Chef-Solo in order to build out an EFK stack for rapid analysis.

Mission Statement
=================

This repo has the grandiose notion that you can go from an empty host with only Oracle Virtualbox and Vagrant installed to a fully functional EFK (Elasticsearch/Fluentd/Kibana) stack for rapid data analysis in under an hour (less if you already have a base Debian .box lying around). Through trial and error, I've managed to hone in the bare minimum for setting up two boxes that make this happen. The first is an ELK stack box that runs Elasticsearch and Kibana. The second is a Fluentd box that runs Fluentd-UI so that Fluentd's config file can be easily managed through a web interface. I've also found that a lot of configuration files can be pushed through chef-solo as part of the Vagrant provisioning. There's still plenty to do here though in order to make this fully functional.

To Do
-----
[ ] 1. Stand up a webserver for Chef Server and to serve out Vagrant boxes (~600mb - 2gb in size each, depending)
[ ] 2. Write an input module for Fluentd to ingest L2T formatted files natively rather than hobbling together a regexp
[ ] 3. Build out ingestion rules for Fluentd and log files (note: apache, nginx, and several others are already built-in)
[ ] 4. Compile a master script to pull down latest Vagrantfiles, knife in latest cookbooks, and start Vagrant process automagically
[ ] 5. As an intermediate step, build out a self-extracting zip for these two boxes

Requirements
------------
 - Oracle Virtualbox
 - Vagrant
 - A folder named C:\Data (or edit the Vagrantfiles accordingly to change the sync folder)
 - Internet connection (for Chef to use gems and apt)

Notes
-----
 - This is extremely hacky and parts of it can almost certainly be done better, more efficiently, and more safely
 - A lot of shortcuts have been taken in making this a proof of concept - there are several things hardwired in that you will want to change in your own environment
 - Bridging adapters is a short term solution; please evaluate if this is right for your environment
 
 Cheers!
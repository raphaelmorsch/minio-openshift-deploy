#!/bin/bash
oc project minio-ocp
oc adm policy add-scc-to-user anyuid -z default
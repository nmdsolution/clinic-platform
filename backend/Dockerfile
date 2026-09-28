# syntax=docker/dockerfile:1

### Dev Stage
FROM openmrs/openmrs-core:2.8.x-dev-amazoncorretto-21 AS dev
WORKDIR /openmrs_distro

ARG MVN_ARGS="-s /usr/share/maven/ref/settings-docker.xml -U -P distro"
ARG MVN_COMMAND="install"

# Build a patched stockmanagement module: the released 3.0.0 has a dead
# StockOperationDTOValidator, so atLocationUuid is never set and every
# stock operation (Receipt, Opening Stock...) fails with
# "Column 'at_location_id' cannot be null". Fix proposed upstream but not
# yet released: https://github.com/openmrs/openmrs-module-stockmanagement/pull/47
RUN --mount=type=secret,id=m2settings,target=/usr/share/maven/ref/settings-docker.xml \
    git clone https://github.com/ebouJ/openmrs-module-stockmanagement.git /tmp/stockmanagement-fix && \
    cd /tmp/stockmanagement-fix && \
    git checkout 890c93736e591fc3a4fb9977ae260de7b9b371b7 && \
    mvn -s /usr/share/maven/ref/settings-docker.xml -DskipTests install && \
    cd / && rm -rf /tmp/stockmanagement-fix

# Copy build files
COPY pom.xml ./
COPY backend/distro ./backend/distro/

ARG CACHE_BUST
# Build the distro, but only deploy from the amd64 build
RUN --mount=type=secret,id=m2settings,target=/usr/share/maven/ref/settings-docker.xml \
    if [ "$(arch)" != "x86_64" ]; then MVN_ARGS="$MVN_ARGS -Dmaven.deploy.skip=true"; fi && \
    mvn $MVN_ARGS $MVN_COMMAND

RUN cp /openmrs_distro/backend/distro/target/sdk-distro/web/openmrs_core/openmrs.war /openmrs/distribution/openmrs_core/

RUN cp /openmrs_distro/backend/distro/target/sdk-distro/web/openmrs-distro.properties /openmrs/distribution/
RUN cp -R /openmrs_distro/backend/distro/target/sdk-distro/web/openmrs_modules /openmrs/distribution/openmrs_modules/
RUN cp -R /openmrs_distro/backend/distro/target/sdk-distro/web/openmrs_owas /openmrs/distribution/openmrs_owas/
RUN cp -R /openmrs_distro/backend/distro/target/sdk-distro/web/openmrs_config /openmrs/distribution/openmrs_config/

# Replace OpenMRS branding logo in Legacy UI with clinic logo (done here in dev stage as root)
COPY frontend/custom-modules/esm-login-app/src/logo-clinic.png /tmp/logo-clinic.png
RUN mkdir -p /tmp/logo/images && \
    cp /tmp/logo-clinic.png /tmp/logo/images/openmrs_logo_white.gif && \
    cp /openmrs/distribution/openmrs_core/openmrs.war /tmp/logo/openmrs.war && \
    cd /tmp/logo && \
    jar xf openmrs.war WEB-INF/classes/messages.properties && \
    sed -i 's/^openmrs\.title=.*/openmrs.title=HGest/' WEB-INF/classes/messages.properties && \
    jar uf openmrs.war images/openmrs_logo_white.gif WEB-INF/classes/messages.properties && \
    cp openmrs.war /openmrs/distribution/openmrs_core/openmrs.war && \
    rm -rf /tmp/logo /tmp/logo-clinic.png

# Clean up after copying needed artifacts
RUN mvn $MVN_ARGS clean

### Run Stage
FROM openmrs/openmrs-core:2.8.x-amazoncorretto-21

COPY --from=dev /openmrs/distribution/openmrs_core/openmrs.war /openmrs/distribution/openmrs_core/

COPY --from=dev /openmrs/distribution/openmrs-distro.properties /openmrs/distribution/
COPY --from=dev /openmrs/distribution/openmrs_modules /openmrs/distribution/openmrs_modules
COPY --from=dev /openmrs/distribution/openmrs_owas /openmrs/distribution/openmrs_owas
COPY --from=dev  /openmrs/distribution/openmrs_config /openmrs/distribution/openmrs_config



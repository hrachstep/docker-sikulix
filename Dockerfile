FROM java:8

# install google chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
RUN apt-get -y update
RUN apt-get install -y google-chrome-stable

# install chromedriver
RUN apt-get install -yqq unzip
RUN wget -O /tmp/chromedriver.zip http://chromedriver.storage.googleapis.com/`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE`/chromedriver_linux64.zip
RUN unzip /tmp/chromedriver.zip chromedriver -d /usr/local/bin/

# set display port to avoid crash
ENV DISPLAY=:99

# install selenium
RUN pip install selenium==3.8.0

RUN echo "Install requirements:" \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
        libopencv-core2.4 \
        libopencv-highgui2.4 \
        libtesseract3 \
        wmctrl \
        xdotool \
        xvfb \
        xauth \
 && apt-get clean \

 && echo "Workaround lsb_release showing errors when missing:" \
 && printf "#/bin/sh\nuname -a\n" >/usr/bin/lsb_release \
 && chmod +x /usr/bin/lsb_release \

 && echo "Download and install SikuliX:" \
 && DOWNLOAD_URL=$(curl -L https://launchpad.net/sikuli/sikulix/ | grep -Po '(?<=href=")https://launchpad.net/sikuli/sikulix/[^"]+download[^"]+') \
 && DOWNLOAD_URL=$(curl -L http://nightly.sikuli.de/ | grep -Po '(?<=href=")https://[^"]+/sikulixsetup-[^"]+\.jar') \
 && mkdir /sikulix \
 && curl -L $DOWNLOAD_URL -o /sikulix/sikulix-setup.jar \
 && xvfb-run java -jar /sikulix/sikulix-setup.jar options 1.1 \

 && echo "Make SikuliX binaries available for everyone:" \
 && chmod +x /sikulix/sikulix.jar /sikulix/runsikulix \
 && ln -s /sikulix/runsikulix /usr/local/bin/ \
 && ln -s /sikulix/sikulix.jar /usr/local/bin/ \

 && echo "Create default home directory:" \
 && mkdir /home/sikulix \
 && chmod ugo+rwx /home/sikulix \

 && echo "Clean-up:" \
 && apt-get purge --auto-remove -y \
        xvfb \
 && rm -rf /var/lib/apt/lists/* /tmp/* /sikulix/sikulix-setup.jar /sikulix/*-SetupLog.txt /sikulix/SetupStuff

VOLUME /home/sikulix

ENV HOME /home/sikulix
ENV _JAVA_OPTIONS -Duser.home=/home/sikulix

CMD ["/sikulix/runsikulix"]

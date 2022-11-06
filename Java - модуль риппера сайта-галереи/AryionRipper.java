package com.rarchives.ripme.ripper.rippers;

import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.HashMap;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
//just for filesystem handling override
import java.util.Map;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;

import org.jsoup.Connection.Response;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;

import com.rarchives.ripme.ripper.AbstractHTMLRipper;
import com.rarchives.ripme.ripper.DownloadThreadPool;
import com.rarchives.ripme.ui.RipStatusMessage.STATUS;
import com.rarchives.ripme.utils.Http;
import static com.rarchives.ripme.utils.RipUtils.getCookiesFromString;
//just for filesystem handling override
import com.rarchives.ripme.App;
import com.rarchives.ripme.utils.Utils;

public class AryionRipper extends AbstractHTMLRipper {
    private List<String> rootPath = new ArrayList<>();
    // TODO: exploration needed, but bailout can help
    private HashSet<String> folderTypes = new HashSet<>(Arrays.asList("Folders", "Comics")); 
    private HashSet<String> urlHistory = new HashSet<>(); //gah!
    private Pattern filenameRE = Pattern.compile("filename=\\\"(.+)\\\"");
    private DownloadThreadPool AryionThreadPool;
    private Map<String, String> cookies = new HashMap<>();

    public AryionRipper(URL url) throws IOException {
        super(url);
        this.AryionThreadPool = new DownloadThreadPool("Aryion");
    }

    @Override
    public String getHost() {
        return "aryion";
    }

    @Override
    public String getDomain() {
        return "aryion.com";
    }

    @Override
    public boolean hasASAPRipping() {
        return true;
    }

    @Override
    public DownloadThreadPool getThreadPool() {
        return this.AryionThreadPool;
    }

    private void setCookies() {
        if (Utils.getConfigBoolean("aryion.login", false)) {
            LOGGER.info("Logging in using cookies");
            String aryionCookies = Utils.getConfigString("aryion.cookies", "");
            if (aryionCookies.isEmpty()) {
                sendUpdate(STATUS.DOWNLOAD_ERRORED,"WARNING: cookies to Aryion account were not provided, fallback to no login ripping");
            } else {
                sendUpdate(STATUS.DOWNLOAD_ERRORED,"ATTENTION: Ripping Aryion using account cookies");
                this.cookies = getCookiesFromString(aryionCookies);
            }
        }
    }

    @Override
    public void downloadURL(URL url, int index) {
        addURLToDownload(url, getPrefix(index));
    }

    @Override
    public String getGID(URL url) throws MalformedURLException {
        Pattern pat_folder = Pattern.compile("^https?://aryion\\.com/g4/view/([0-9]+).*$");
        Matcher mat_folder = pat_folder.matcher(url.toExternalForm());
        if (mat_folder.matches())
            return mat_folder.group(1);

        Pattern pat_gallery = Pattern.compile("^https?://aryion\\.com/g4/gallery/([a-zA-Z0-9-_]+).*$");
        Matcher mat_gallery = pat_gallery.matcher(url.toExternalForm());
        if (mat_gallery.matches())
            return mat_gallery.group(1);

        throw new MalformedURLException("Expected aryion.com URL format: "
                + "aryion.com/g4/view/folderid or .../g4/gallery/artist - got " + url + " instead");
    }

    protected List<String> getDirectoryPath(Document page) {
        List<String> path = new ArrayList<>();
        for (Element link : page.select(".g-box-title > a"))
            path.add(filesystemLessSafe(link.text()));
        path.add(filesystemLessSafe(page.select(".g-box-title").first().text().replace(">", "")));
        return path;
    }

    // just added () in the first regexp, parentheses used a lot in folders' names,
    // and it's safe for fs, come on
    private static String filesystemLessSafe(String text) {
        text = text.replaceAll("[^a-zA-Z0-9.()-]", "_").replaceAll("__", "_").replaceAll("_+$", "");
        if (text.length() > 100) {
            text = text.substring(0, 99);
        }
        return text;
    }

    // just added ()/ in the first regexp, slash is safe after stripping it out in
    // subdirectories' names before
    private static String filesystemSafeWithSubfolders(String text) {
        text = text.replaceAll("[^a-zA-Z0-9.()/-]", "_").replaceAll("__", "_").replaceAll("_+$", "");
        if (text.length() > 100) {
            text = text.substring(0, 99);
        }
        return text;
    }

    @Override
    public Document getFirstPage() throws IOException {
        setCookies();
        Document pageCache = Http.url(url).cookies(cookies).get();
        this.rootPath = getDirectoryPath(pageCache); // important to remember root
        // make proper url_history index
        try (BufferedReader reader = new BufferedReader(new FileReader(Utils.getURLHistoryFile()))) {
            for (String line = reader.readLine(); line != null; line = reader.readLine()) //TODO: can we do it simple?
                urlHistory.add(line);
        } catch (IOException e) {
            LOGGER.warn("Failed to read url history file");
        }
        return pageCache;
    }

    //just dummy for superclass
    @Override
    public Document getNextPage(Document page) throws IOException {
        throw new IOException("All pages already processed.");
    }

    private Document getNextPageReal(Document page) throws IOException {
        Element next = page.select(".pagenav > a").last();
        if (next != null && next.text().equals("Next >>")) {
            sendUpdate(STATUS.LOADING_RESOURCE, "next page"); //this needs to be there, actually
            return Http.url(next.attr("abs:href")).cookies(cookies).get();
        } else
            throw new IOException("No more pages.");
    }

    //this method tries to queue-download all folder content with threadpool in one run, no official next pages, no returns (for now)
    @Override
    public List<String> getURLsFromPage(Document page) {
        //get directory path relative to provided root
        List<String> relPathList = getDirectoryPath(page);
        relPathList = relPathList.subList(this.rootPath.size(), relPathList.size());
        String relPath = String.join("/", relPathList);
        Integer index = 0;
        while (page != null) {
            for (Element item : page.select(".gallery-item > div")) {
                String subUrl = item.children().first().attr("abs:href");
                String itemClass = item.select("p > span > span").first().className().replace("biicon11 type-", "");
                if (this.folderTypes.contains(itemClass)) {
                    //recursive ripping of subfolders
                    try {
                        LOGGER.debug("Found \"" + itemClass + "\" type url: " + subUrl);
                        sendUpdate(STATUS.LOADING_RESOURCE, subUrl);
                        Document subPage = Http.url(subUrl).cookies(cookies).get();
                        getURLsFromPage(subPage);
                    } catch (IOException e) {
                        LOGGER.warn("Error while loading subfolder " + subUrl, e);
                    }
                } else {
                    //queue for download all other types
                    index++;
                    LOGGER.debug("Found \"" + itemClass + "\" type url #" + index + ": " + subUrl);
                    this.AryionThreadPool.addThread(new AryionDownloadThread(subUrl, relPath, index));
                }
                if (isStopped()) return new ArrayList<>();
            }
            //next page handler for all folders, cause how else do i supposed to do it properly
            try {
                page = getNextPageReal(page);
            } catch (IOException e) {
                LOGGER.info("Can't get next page: " + e.getMessage());
                page = null;
            }
        }  
        return new ArrayList<>();
    }

    @Override
    protected boolean hasDownloadedURL(String url) {
        return urlHistory.contains(normalizeUrl(url));
    }

    //helper thread class to handle all single downloadable types of urls
    private class AryionDownloadThread extends Thread {
        private String itemUrl;
        private String relPath;
        private int index;

        AryionDownloadThread(String itemUrl, String relPath, Integer index) {
            super();
            this.itemUrl = itemUrl;
            this.relPath = relPath;
            this.index = index;
        }

        @Override
        public void run() {
            try {
                URL urlDirect = new URL(itemUrl.replace("view/", "data.php?id="));
                //check for history BEFORE making ANY requests, copy-pasted from AbstractRipper, such a wokaround...
                if (Utils.getConfigBoolean("remember.url_history", true) && !isThisATest())
                    if (hasDownloadedURL(urlDirect.toExternalForm())) {
                        sendUpdate(STATUS.DOWNLOAD_WARN, "Already downloaded " + urlDirect.toExternalForm());
                        alreadyDownloadedUrls += 1;
                        LOGGER.debug("already downloaded urls counter: " + alreadyDownloadedUrls);
                        return;
                    }
                //send small pre-request (multiple attmpts) for filename, it's really not easy
                //with current arch without this. at least i don't know how to really do it
                String filename = "";
                for (Integer attempts = 0; attempts++ < 5;) {
                    if (isStopped()) return;
                    try {
						//try to get a little bit of it
                        Response resp = Http.url(urlDirect).cookies(cookies).connection()
                            .maxBodySize(1).ignoreContentType(true).execute();
                        //try to extract filename
                        Matcher filenameMatcher = filenameRE.matcher(resp.header("content-disposition"));
                        if (filenameMatcher.find()) {
                            filename = filenameMatcher.group(1);
                            //cool, but we need to ensure we aren't getting a zero payload, in case of folder, for example
                            if (resp.header("content-length").equals("0")) {
                                // bailout in case of zero-length content, seems like unregistered folder type
                                sendUpdate(STATUS.DOWNLOAD_ERRORED,
                                        "Attention! Apparently unsupported folder type found! Trying to treat like a folder. Please, notify developer if possible, the problem url is: "
                                                + itemUrl);
                                LOGGER.error("Url with content-length = 0, trying to bailout to folder type: " + itemUrl);
                                sendUpdate(STATUS.LOADING_RESOURCE, itemUrl);
                                try {
                                    Document pageTrial = Http.url(itemUrl).cookies(cookies).get();
                                    // now check for path on this assumed page, it must be present in folders
                                    if (!getDirectoryPath(pageTrial).isEmpty()) {
                                        getURLsFromPage(pageTrial);
                                    } else {
                                        // we are really fucked up, no bailout can help...
                                        sendUpdate(STATUS.DOWNLOAD_ERRORED,
                                                "Parsing page like a folder failed. Please, notify developer if possible, the problem url is: "
                                                        + itemUrl);
                                        LOGGER.error("Unable to recognize page like a folder type: " + itemUrl);
                                    }
                                } catch (IOException e) {
                                    LOGGER.warn("Error while trying to load url like a subfolder " + itemUrl, e);
                                }
                                return;
                            } else break;
                        } else
                            LOGGER.warn("For " + attempts + "th time can't extract filename from header: \"" + resp.header("content-disposition") + "\" in " + urlDirect);
                    } catch (IOException | IndexOutOfBoundsException e) {
                        LOGGER.warn("Error on the " + attempts + "th time while getting filename for " + urlDirect, e);
                    }
                    //try to wait for a second, maybe later
                    try {
                        Thread.sleep(1000);
                    } catch (InterruptedException e) {
                        LOGGER.error("Interrupted while waiting to try to get filename again", e);
                    }
                }
                //bailout for filename, just in case
                if (filename.isEmpty()) {
                    sendUpdate(STATUS.DOWNLOAD_WARN, "Error after multiple attempts to get filename for " + itemUrl);
                    filename = getGID(new URL(itemUrl));
                }
                // actually queue for download
                addURLToDownload(urlDirect, getPrefix(index), relPath, null, cookies, filesystemLessSafe(filename), null, false);
            } catch (MalformedURLException e) {
                LOGGER.error("\"" + itemUrl + "\" is malformed");
            }
        }
    }

    //TODO: just for 1-line change, awful. but i want nested subfolders badly and don't want to change other files for now
    @Override
    protected boolean addURLToDownload(URL url, String prefix, String subdirectory, String referrer,
            Map<String, String> cookies, String fileName, String extension, Boolean getFileExtFromMIME) {
        // A common bug is rippers adding urls that are just "http:". This rejects said
        // urls
        if (url.toExternalForm().equals("http:") || url.toExternalForm().equals("https:")) {
            LOGGER.info(url.toExternalForm() + " is a invalid url amd will be changed");
            return false;

        }
        // Make sure the url doesn't contain any spaces as that can cause a 400 error
        // when requesting the file
        if (url.toExternalForm().contains(" ")) {
            // If for some reason the url with all spaces encoded as %20 is malformed print
            // an error
            try {
                url = new URL(url.toExternalForm().replaceAll(" ", "%20"));
            } catch (MalformedURLException e) {
                LOGGER.error("Unable to remove spaces from url\nURL: " + url.toExternalForm());
                e.printStackTrace();
            }
        }
        // Don't re-add the url if it was downloaded in a previous rip
        if (Utils.getConfigBoolean("remember.url_history", true) && !isThisATest()) {
            if (hasDownloadedURL(url.toExternalForm())) {
                sendUpdate(STATUS.DOWNLOAD_WARN, "Already downloaded " + url.toExternalForm());
                alreadyDownloadedUrls += 1;
                return false;
            }
        }
        try {
            stopCheck();
        } catch (IOException e) {
            LOGGER.debug("Ripper has been stopped");
            return false;
        }
        LOGGER.debug("url: " + url + ", prefix: " + prefix + ", subdirectory" + subdirectory + ", referrer: " + referrer
                + ", cookies: " + cookies + ", fileName: " + fileName);
        String saveAs = getFileName(url, fileName, extension);
        File saveFileAs;
        try {
            if (!subdirectory.equals("")) {
                subdirectory = filesystemSafeWithSubfolders(subdirectory); // the only change
                subdirectory = File.separator + subdirectory;
            }
            prefix = Utils.filesystemSanitized(prefix);
            String topFolderName = workingDir.getCanonicalPath();
            if (App.stringToAppendToFoldername != null) {
                topFolderName = topFolderName + App.stringToAppendToFoldername;
            }
            saveFileAs = new File(topFolderName + subdirectory + File.separator + prefix + saveAs);
        } catch (IOException e) {
            LOGGER.error("[!] Error creating save file path for URL '" + url + "':", e);
            return false;
        }
        LOGGER.debug("Downloading " + url + " to " + saveFileAs);
        if (!saveFileAs.getParentFile().exists()) {
            LOGGER.info("[+] Creating directory: " + Utils.removeCWD(saveFileAs.getParent()));
            saveFileAs.getParentFile().mkdirs();
        }
        if (Utils.getConfigBoolean("remember.url_history", true) && !isThisATest()) {
            LOGGER.info("Writing " + url.toExternalForm() + " to file");
            try {
                writeDownloadedURL(url.toExternalForm() + "\n");
            } catch (IOException e) {
                LOGGER.debug("Unable to write URL history file");
            }
        }
        return addURLToDownload(url, saveFileAs, referrer, cookies, getFileExtFromMIME);
    }
}

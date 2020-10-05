package app.covidshield.Manager;

import android.content.Context;

import com.google.android.gms.nearby.Nearby;
import com.google.common.collect.ImmutableList;
import com.google.common.util.concurrent.FluentFuture;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;

import org.threeten.bp.Duration;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;

/**
 * A facade to network operations to download all known Diagnosis Keys.
 *
 * <p>The download is a file fetch.
 *
 * <p>In the future we could use this facade to switch between using a live test server and internal
 * faked implementations.
 */
public class DiagnosisKeys {

    private final DiagnosisKeyDownloader diagnosisKeyDownloader;

    public DiagnosisKeys(Context context) {
        diagnosisKeyDownloader = new DiagnosisKeyDownloader(context.getApplicationContext());
    }

    public ListenableFuture<ImmutableList<KeyFileBatch>> download() {
        return diagnosisKeyDownloader.download();
    }

    public ListenableFuture<List<File>> downloadKeys(Context context){
        return FluentFuture.from(TaskToFutureAdapter
                .getFutureWithTimeout(
                        Nearby.getExposureNotificationClient(context).isEnabled(),
                        Duration.ofSeconds(10).toMillis(),
                        TimeUnit.MILLISECONDS,
                        AppExecutors.getScheduledExecutor()))
                .transformAsync((isEnabled) -> {
                    // Only continue if it is enabled.
                    if (isEnabled) {
                        // Download diagnosis keys from Safe Paths servers
                        return download();
                    } else {
                        // Stop here because things aren't enabled. Will still return successful though.
                        return Futures.immediateFailedFuture(new Exception());
                    }
                }, AppExecutors.getBackgroundExecutor())
                // Submit downloaded files to EN client
                .transform(this::submitFiles, AppExecutors.getBackgroundExecutor());
    }

    public List<File> submitFiles(ImmutableList<KeyFileBatch> batches) {
        List<File> files = new ArrayList<>();
        for (KeyFileBatch b : batches) {
            files.addAll(b.files());
        }
        return files;
    }
}

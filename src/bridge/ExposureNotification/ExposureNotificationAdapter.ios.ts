import {unzip} from 'react-native-zip-archive';
import {captureMessage} from 'shared/log';

import {ExposureNotification, ExposureSummary} from './types';
import {getLastExposureTimestamp} from './utils';

export default function ExposureNotificationAdapter(exposureNotificationAPI: any): ExposureNotification {
  return {
    ...exposureNotificationAPI,
    detectExposure: async (configuration, diagnosisKeysURLs) => {
      const summaries: ExposureSummary[] = [];
      if (diagnosisKeysURLs.length === 0) {
        throw new Error('Attempt to call detectExposure with empty list of downloaded files');
      }
      captureMessage('diagnosisKeysURLs.length', {length: diagnosisKeysURLs.length});

        const summary: ExposureSummary = await exposureNotificationAPI.detectExposure(configuration, diagnosisKeysURLs);

        captureMessage('ExposureNotificationAdapter.iOS - detectExposure', {summary});

        summary.lastExposureTimestamp = getLastExposureTimestamp(summary);
        if (summary.matchedKeyCount > 0) {
          summaries.push(summary);
        }

      return summaries!;
    },
    getPendingExposureSummary: async () => undefined,
  };
}

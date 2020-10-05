import { Buffer } from 'buffer';

//import hmac256 from 'crypto-js/hmac-sha256';
// import encHex from 'crypto-js/enc-hex';
import { ExposureNotification, TemporaryExposureKey } from 'bridge/ExposureNotification';
// import { MCC_CODE } from 'env';
import { ContagiousDateInfo } from 'screens/datasharing/components';

import { Observable } from '../../shared/Observable';
import { Region } from '../../shared/Region';

import { BackendInterface, SubmissionKeySet } from './types';

import { postCode, postTokenAndHmac } from '../ExposureNotificationService/verificationAPI'
import { calculateHmac } from '../ExposureNotificationService/hmac';
import { postDiagnosisKeys } from '../ExposureNotificationService/exposureNotificationAPI';
import { BackendService as BackendServiceBase } from 'services/BackendService';
import { ExposureKey } from '../ExposureNotificationService/exposureKey'

const MAX_UPLOAD_KEYS = 14;
const TRANSMISSION_RISK_LEVEL = 1;

// See https://github.com/cds-snc/covid-shield-server/pull/176
const LAST_14_DAYS_PERIOD = '00000';

export class BackendService extends BackendServiceBase implements BackendInterface {
  retrieveUrl: string;
  submitUrl: string;
  hmacKey: string;
  region: Observable<Region | undefined> | undefined;

  constructor(
    retrieveUrl: string,
    submitUrl: string,
    hmacKey: string,
    region: Observable<Region | undefined> | undefined,
  ) {
    super(retrieveUrl, submitUrl, hmacKey, region);
    this.retrieveUrl = retrieveUrl;
    this.submitUrl = submitUrl;
    this.hmacKey = hmacKey;
    this.region = region;
  }


  async claimOneTimeCode(oneTimeCode: string, exposureKeys: TemporaryExposureKey[]): Promise<SubmissionKeySet> {

    const verificationReponse = await postCode(oneTimeCode);
    let serverPublicKey = '';
    if (verificationReponse.kind == "success") {
      console.log("verification success token=", verificationReponse.body.token)
      const token = verificationReponse.body.token

      const _exposureKeys: ExposureKey[] = []
      exposureKeys.forEach((item: TemporaryExposureKey) => {
        _exposureKeys.push({
          key: item.keyData,
          rollingPeriod: item.rollingPeriod,
          rollingStartNumber: item.rollingStartIntervalNumber,
          transmissionRisk: item.transmissionRiskLevel
        })
      });

      const [hmacDigest, hmacKey] = await calculateHmac(_exposureKeys)

      this.hmacKey = hmacKey;


      console.log("postTokenAndHmac hmacKey==", this.hmacKey);
      console.log("Make  postTokenAndHmac call")
      console.log("postDiagnosisKeys exposureKeys=", exposureKeys);
      const certResponse = await postTokenAndHmac(token, hmacDigest)

      console.log("postTokenAndHmac certResponse=", certResponse)
      if (certResponse.kind === "success") {
        serverPublicKey = certResponse.body.certificate
        console.log("certificate==", serverPublicKey)

      }
    }

    return {
      serverPublicKey: serverPublicKey,
      clientPrivateKey: '',
      clientPublicKey: ''
    }
  }

  async reportDiagnosisKeys(
    keyPair: SubmissionKeySet,
    _exposureKeys: TemporaryExposureKey[],
    contagiousDateInfo: ContagiousDateInfo,
  ) {

    const revisionToken = '';
    const exposureKeys: ExposureKey[] = []
    const appPackageName = '';
    const regions: Region = [];
    const contagiousDateInfo1 = contagiousDateInfo;

    _exposureKeys.forEach((item) => {
      exposureKeys.push({
        key: item.keyData,
        rollingPeriod: item.rollingPeriod,
        rollingStartNumber: item.rollingStartIntervalNumber,
        transmissionRisk: item.transmissionRiskLevel
      })
    });

    console.log("calling postDiagnosisKeys");
    console.log("postDiagnosisKeys exposureKeys=", exposureKeys);
    console.log("postDiagnosisKeys hmacKey==", this.hmacKey);

    await postDiagnosisKeys(
      exposureKeys,
      regions,
      keyPair.serverPublicKey,
      this.hmacKey,
      appPackageName,
      revisionToken,

    )

  }

}

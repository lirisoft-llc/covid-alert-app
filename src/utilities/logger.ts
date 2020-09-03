const RNFS = require('react-native-fs');

const fileLog = (message: string) => {
  const path = RNFS.DocumentDirectoryPath + '/logs.txt';
  console.log('file path: ' + path)

  // write the file
  RNFS.exists(path)
    .then((exists) => {
      if (exists) {
        RNFS.appendFile(path, message, 'utf8')
          .then(() => {
            console.log('FILE WRITTEN!');
          })
          .catch((err: Error) => {
            console.log('ERROR WRITING FILE');
            console.log(err.message);
          });
      } else {
        RNFS.writeFile(path, message, 'utf8')
          .then(() => {
            console.log('FILE WRITTEN!');
          })
          .catch((err: Error) => {
            console.log('ERROR WRITING FILE');
            console.log(err.message);
          });
      }
    })
    .catch(() => {

    });
}

export default fileLog

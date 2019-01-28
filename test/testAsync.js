
const print = console.log;
const delay = (duration) => new Promise((resolve, reject) => setTimeout(() => resolve(), duration));



oneSecondLater = () => {
  print('before Future.delayed');
  var a = delay(1000);
  print('after Future.delayed');
  return a;
}

delayOneSecond = async () => {
  print('before delay')
  await delay(0);
}

printDailyNewsDigest = async () => {
  await delayOneSecond();
  print('before await str');
  var str = await oneSecondLater();
  print(str);
}

setImmediate(() => print('0.1'));
setTimeout(() => print('0.2'), 0);
process.nextTick(() => print('0.3'));
print('1');
printDailyNewsDigest().then(() => print('printDailyNewsDigest'));
print('2');
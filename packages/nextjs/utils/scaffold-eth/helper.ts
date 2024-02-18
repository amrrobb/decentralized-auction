export function getTimeLeft(timestampString: string | bigint) {
  // Convert the string to a BigInt
  const timestamp = BigInt(timestampString);

  // Convert BigInt to milliseconds by multiplying by 1000n
  const targetTime = Number(timestamp) * 1000;

  // Get the current time in milliseconds
  const currentTime = Date.now();

  // Calculate the difference in milliseconds
  let difference = targetTime - currentTime;

  // Check if the target time is in the past
  if (difference <= 0) {
    return "-";
  }

  // Calculate days, hours, minutes, and seconds
  const days = Math.floor(difference / (1000 * 60 * 60 * 24));
  difference %= 1000 * 60 * 60 * 24;
  if (days > 0) {
    return `${days} days`;
  }

  const hours = Math.floor(difference / (1000 * 60 * 60));
  difference %= 1000 * 60 * 60;
  if (hours > 0) {
    return `${hours} hours`;
  }

  const minutes = Math.floor(difference / (1000 * 60));
  difference %= 1000 * 60;
  if (minutes > 0) {
    return `${minutes} minutes`;
  }

  const seconds = Math.floor(difference / 1000);
  if (seconds > 0) {
    return `${seconds} seconds`;
  }
}

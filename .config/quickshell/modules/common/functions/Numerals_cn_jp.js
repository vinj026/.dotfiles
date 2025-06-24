function toChineseNumeral(num) {
  const chineseNumerals = ['一', '二', '三', '四', '五', '六', '七', '八', '九', '十'];

  if (num >= 1 && num <= chineseNumerals.length) {
    return chineseNumerals[num - 1];
  }
  return num.toString();
}

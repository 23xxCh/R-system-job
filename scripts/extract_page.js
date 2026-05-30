// extract_page.js —— 从智联招聘页面提取岗位数据
// 通过 kimi-webbridge evaluate 调用
// 返回 JSON 字符串
(function() {
  var cards = document.querySelectorAll('.joblist-box__item');
  var jobs = [];
  for (var i = 0; i < cards.length; i++) {
    var c = cards[i];
    var t = c.querySelector('.jobinfo__name');
    var s = c.querySelector('.jobinfo__salary');
    var cp = c.querySelector('.companyinfo__name');
    var o = c.querySelectorAll('.jobinfo__other-info-item');
    var g = c.querySelectorAll('.companyinfo__tag .joblist-box__item-tag');
    if (t) {
      jobs.push({
        t: t.textContent.trim(),
        s: s ? s.textContent.trim() : '',
        cp: cp ? cp.textContent.trim() : '',
        ci: o[0] ? o[0].textContent.trim() : '',
        e: o[1] ? o[1].textContent.trim() : '',
        ed: o[2] ? o[2].textContent.trim() : '',
        sz: g[1] ? g[1].textContent.trim() : '',
        'in': g[2] ? g[2].textContent.trim() : ''
      });
    }
  }
  return JSON.stringify(jobs);
})()

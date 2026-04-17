<!DOCTYPE html>
<html lang="ja">
<head>
  <base target="_top">
  <meta charset="UTF-8">
  <?!= include('styles'); ?>
</head>
<body>
  <div class="app">
    <!-- ===== 共通ヘッダ ===== -->
    <header class="app-header">
      <h1 class="app-title"><span class="icon" id="appIcon">📋</span><span id="appTitle">永晃産業 発注管理</span></h1>
      <nav class="breadcrumb" id="appBreadcrumb"></nav>
    </header>

    <!-- ===== ① ダッシュボード ===== -->
    <section data-page="menu" style="display:none">
      <div class="dash-grid" id="dashTiles"></div>
      <div class="card">
        <div style="display:flex; justify-content:space-between; align-items:center">
          <h2 class="mb-0">進行中案件</h2>
          <span class="small" id="dashHint"></span>
        </div>
        <div class="project-list" id="projectList" style="margin-top:12px">
          <span class="small">読み込み中...</span>
        </div>
      </div>
      <div class="menu-grid" style="margin-top:24px">
        <a class="menu-card" data-nav="new_order">
          <span class="icon">📝</span>
          <span class="title">新規注文入力</span>
          <span class="desc">仕入先・明細を入力 → 発注番号採番 → 注文書発行</span>
        </a>
        <a class="menu-card" data-nav="search">
          <span class="icon">🔍</span>
          <span class="title">検索</span>
          <span class="desc">新規発注と過去累計を横断検索</span>
        </a>
        <a class="menu-card" data-nav="delivery">
          <span class="icon">📦</span>
          <span class="title">納品日登録</span>
          <span class="desc">納期回答・入荷・仕上がりを更新</span>
        </a>
      </div>
    </section>

    <!-- ===== ② 新規注文 / 編集 ===== -->
    <section data-page="new_order" style="display:none">
      <div class="toolbar" id="newOrderTopActions">
        <button type="button" id="copyBtn" onclick="openCopyPicker()">📋 過去注文から複製</button>
        <span id="editingHeader" class="hidden small">編集中: <b id="editingNo"></b></span>
      </div>

      <div class="card">
        <h2>注文書に載る項目</h2>
        <div class="form-row two-col">
          <label>仕入先名<span class="hint">※必須</span></label>
          <input type="text" id="supplier" placeholder="例: スギコ産業㈱" list="suppliers" autocomplete="off">
          <label>発注日</label>
          <input type="date" id="orderDate">
          <label>納期</label>
          <input type="date" id="deliveryDate">
          <label>担当者</label>
          <input type="text" id="person" placeholder="例: 松林" list="persons" autocomplete="off">
        </div>
        <p class="card-section-hint">候補は「仕入先マスタ」「担当者マスタ」シートから自動表示。マスタにない場合は自由入力もOK（保存時にマスタ追加を聞きます）。</p>
      </div>
      <datalist id="suppliers"></datalist>
      <datalist id="persons"></datalist>
      <datalist id="items"></datalist>

      <div class="card card-muted">
        <h2>社内管理項目 <span class="badge badge-confirmed">PDF非表示</span></h2>
        <p class="card-section-hint">注文書には出さず、累計DBにのみ保存します。</p>
        <div class="form-row two-col">
          <label>用途（案件名）</label>
          <input type="text" id="usage" placeholder="どの製品・案件で使うか">
          <label>社内メモ</label>
          <input type="text" id="internalMemo" placeholder="内部連絡事項">
        </div>
      </div>

      <div class="card">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:8px">
          <h2 class="mb-0">明細</h2>
          <button type="button" class="ghost" onclick="addRow()">＋ 行を追加</button>
        </div>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th style="width:3em">#</th>
                <th>品名</th>
                <th style="width:8em">数量</th>
                <th style="width:8em">単価</th>
                <th style="width:9em">金額</th>
                <th>備考</th>
                <th style="width:3em"></th>
              </tr>
            </thead>
            <tbody id="itemsBody"></tbody>
          </table>
        </div>
      </div>

      <div class="toolbar">
        <button class="primary" type="button" onclick="save()" id="saveBtn">保存して注文書を発行</button>
        <span class="grow"></span>
        <a class="btn ghost" data-nav="menu">キャンセル</a>
      </div>
    </section>

    <!-- ===== ③ 注文書プレビュー ===== -->
    <section data-page="order_pdf" style="display:none">
      <div class="no-print toolbar" id="orderPdfActions">
        <button class="primary" type="button" onclick="window.print()">🖨️ 印刷 / PDF保存</button>
        <a class="btn" id="editLink" data-nav="new_order">✏️ 編集</a>
        <button class="btn danger" id="cancelBtn" onclick="cancelThis()">🚫 取消</button>
        <button class="btn" id="restoreBtn" onclick="restoreThis()" style="display:none">↩ 復活</button>
        <span class="grow"></span>
        <span class="small no-print">ブラウザの印刷ダイアログで「送信先 → PDF に保存」を選ぶとPDFになります。</span>
      </div>
      <div id="orderDoc" class="order-doc"></div>
    </section>

    <!-- ===== ④ 検索 ===== -->
    <section data-page="search" style="display:none">
      <div class="card">
        <div class="form-row two-col">
          <label>キーワード</label>
          <input type="text" id="searchText" placeholder="品名・備考・発注番号 など">
          <label>仕入先／会社名</label>
          <input type="text" id="searchSupplier" placeholder="部分一致">
          <label>用途（案件）</label>
          <input type="text" id="searchUsage" placeholder="部分一致">
          <label>ステータス</label>
          <select id="searchStatus">
            <option value="">（指定なし）</option>
            <? getStatusList().forEach(function(s) { ?>
              <option><?= s ?></option>
            <? }) ?>
          </select>
          <label>日付 From</label>
          <input type="date" id="searchDateFrom">
          <label>日付 To</label>
          <input type="date" id="searchDateTo">
          <label>対象</label>
          <select id="searchSource">
            <option value="both">新規＋過去累計</option>
            <option value="orders">新規のみ</option>
            <option value="legacy">過去累計のみ</option>
          </select>
        </div>
        <div class="toolbar">
          <button class="primary" onclick="runSearch()">検索</button>
          <button class="ghost" onclick="clearSearch()">条件クリア</button>
          <span class="grow"></span>
          <span id="presetLabel" class="small"></span>
          <span id="searchSummary" class="small"></span>
        </div>
      </div>

      <div class="card">
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>発注番号</th>
                <th>仕入先／会社</th>
                <th>品名</th>
                <th>数量</th>
                <th>発注日</th>
                <th>納期</th>
                <th>納品予定</th>
                <th>入荷</th>
                <th>仕上</th>
                <th>状態</th>
                <th>用途</th>
                <th>出典</th>
                <th></th>
              </tr>
            </thead>
            <tbody id="searchRows">
              <tr><td colspan="13" class="small" style="text-align:center; padding:32px">条件を入力して「検索」を押してください。</td></tr>
            </tbody>
          </table>
        </div>
      </div>
    </section>

    <!-- ===== ⑤ 納品日登録 ===== -->
    <section data-page="delivery" style="display:none">
      <div class="card">
        <div class="form-row">
          <label>発注番号</label>
          <div style="display:flex; gap:8px">
            <input type="text" id="lookupOrderNumber" placeholder="例: 260408001" style="flex:1">
            <button class="primary" onclick="loadOrderForDelivery()">呼び出し</button>
          </div>
        </div>
      </div>
      <div id="deliveryDetail" class="card hidden">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px">
          <h2 class="mb-0" id="deliveryTitle"></h2>
          <a id="deliveryPdfLink" class="btn small" data-nav="order_pdf">🖨️ 注文書を開く</a>
        </div>
        <div class="small" id="deliveryMeta" style="margin-bottom:12px"></div>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th style="width:3em">#</th>
                <th>品名</th>
                <th>数量</th>
                <th style="width:12em">納品予定日</th>
                <th style="width:12em">入荷日</th>
                <th style="width:12em">仕上日</th>
                <th>状態</th>
                <th></th>
              </tr>
            </thead>
            <tbody id="deliveryRows"></tbody>
          </table>
        </div>
      </div>
    </section>
  </div>

  <script>
    /* ============================================================
     * 永晃産業 発注管理アプリ — フロント (SPA)
     * ------------------------------------------------------------
     * 【目次】
     *   ■ 共通定数・ヘルパ
     *   ■ ルーター
     *   ■ ① ダッシュボード
     *   ■ ② 新規注文 / 編集
     *   ■ ③ 注文書プレビュー
     *   ■ ④ 検索
     *   ■ ⑤ 納品日登録
     *   ■ 起動
     * ============================================================ */

    // ■ 共通定数・ヘルパ =========================================

    const APP_URL = <?= JSON.stringify(appUrl) ?>;
    const INITIAL_PARAMS = <?= JSON.stringify(params) ?>;

    const STATUS_CLASS = {
      '発注済': 'badge-ordered',
      '納期回答済': 'badge-confirmed',
      '入荷済': 'badge-arrived',
      '完了': 'badge-done',
      '取消': 'badge-canceled'
    };
    const PROJECT_BAR_CLASS = {
      '発注済': 'seg-ordered',
      '納期回答済': 'seg-confirmed',
      '入荷済': 'seg-arrived'
    };
    const PRESET_LABELS = {
      'overdue': '🚨 納期遅延',
      'this_week': '📅 今週入荷予定',
      'today_finish': '✅ 本日仕上がり'
    };
    const PAGE_TITLES = {
      menu: { icon: '📋', title: '永晃産業 発注管理', breadcrumb: '' },
      new_order: { icon: '📝', title: '新規注文入力', breadcrumb: '新規注文' },
      order_pdf: { icon: '📄', title: '注文書プレビュー', breadcrumb: '注文書' },
      search: { icon: '🔍', title: '検索', breadcrumb: '検索' },
      delivery: { icon: '📦', title: '納品日登録', breadcrumb: '納品日登録' }
    };

    function esc(v) {
      return String(v == null ? '' : v).replace(/[&<>"]/g, function(c) {
        return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c];
      });
    }

    function toast(msg, isErr) {
      let el = document.getElementById('toast');
      if (!el) { el = document.createElement('div'); el.id = 'toast'; document.body.appendChild(el); }
      el.textContent = msg;
      el.classList.toggle('error', !!isErr);
      el.classList.add('show');
      clearTimeout(toast._t);
      toast._t = setTimeout(function() { el.classList.remove('show'); }, isErr ? 4500 : 2500);
    }

    function loadingOn() {
      let el = document.getElementById('loading');
      if (!el) { el = document.createElement('div'); el.id = 'loading'; document.body.appendChild(el); }
      loadingOn._n = (loadingOn._n || 0) + 1;
      el.classList.add('show');
    }
    function loadingOff() {
      loadingOn._n = Math.max(0, (loadingOn._n || 0) - 1);
      if (loadingOn._n === 0) {
        const el = document.getElementById('loading');
        if (el) el.classList.remove('show');
      }
    }

    function call(name) {
      const args = Array.prototype.slice.call(arguments, 1);
      loadingOn();
      return new Promise(function(resolve, reject) {
        google.script.run
          .withSuccessHandler(function(v) { loadingOff(); resolve(v); })
          .withFailureHandler(function(e) { loadingOff(); reject(e); })
          [name].apply(null, args);
      });
    }

    function openModal(html, title) {
      closeModal();
      const back = document.createElement('div');
      back.className = 'modal-backdrop';
      back.innerHTML =
        '<div class="modal">' +
          '<div class="modal-header"><h3>' + (title || '') + '</h3>' +
            '<button class="modal-close" onclick="closeModal()" aria-label="閉じる">×</button></div>' +
          '<div class="modal-body">' + html + '</div>' +
        '</div>';
      back.addEventListener('click', function(e) { if (e.target === back) closeModal(); });
      document.body.appendChild(back);
      return back.querySelector('.modal-body');
    }
    function closeModal() {
      const m = document.querySelector('.modal-backdrop');
      if (m) m.parentNode.removeChild(m);
    }

    /** YYYY-MM-DD → 「令和X年Y月Z日」、それ以外はそのまま返す */
    function formatJpDate(s) {
      if (!s) return '';
      if (!/^\d{4}-\d{1,2}-\d{1,2}$/.test(String(s))) return String(s);
      const parts = String(s).split('-');
      const y = parseInt(parts[0], 10);
      const m = parseInt(parts[1], 10);
      const d = parseInt(parts[2], 10);
      if (y >= 2019) return '令和' + (y - 2018) + '年' + m + '月' + d + '日';
      if (y >= 1989) return '平成' + (y - 1988) + '年' + m + '月' + d + '日';
      return y + '年' + m + '月' + d + '日';
    }


    // ■ ルーター =================================================

    const PAGE_INITS = {
      menu: initMenu,
      new_order: initNewOrder,
      order_pdf: initOrderPdf,
      search: initSearch,
      delivery: initDelivery
    };

    function showPage(name) {
      document.querySelectorAll('section[data-page]').forEach(function(s) {
        s.style.display = (s.dataset.page === name) ? 'block' : 'none';
      });
      const t = PAGE_TITLES[name] || PAGE_TITLES.menu;
      document.getElementById('appIcon').textContent = t.icon;
      document.getElementById('appTitle').textContent = t.title;
      const bc = document.getElementById('appBreadcrumb');
      bc.innerHTML = name === 'menu' ? '' : '<a href="' + APP_URL + '?page=menu">メニュー</a> / ' + esc(t.breadcrumb);
    }

    /** ナビゲーション: フルロード（共有可能URL）。単純な data-nav はクリックで navigate に流れる */
    function navigate(page, extraParams) {
      const parts = ['page=' + encodeURIComponent(page)];
      if (extraParams) {
        Object.keys(extraParams).forEach(function(k) {
          const v = extraParams[k];
          if (v !== undefined && v !== null && v !== '') parts.push(encodeURIComponent(k) + '=' + encodeURIComponent(v));
        });
      }
      window.top.location.href = APP_URL + '?' + parts.join('&');
    }


    // ■ ① ダッシュボード =========================================

    async function initMenu() {
      try {
        const d = await call('getDashboard');
        renderTiles(d);
        renderProjects(d.projects);
        document.getElementById('dashHint').textContent = '本日 ' + new Date().toLocaleDateString('ja-JP') + ' 時点';
      } catch (e) {
        document.getElementById('dashHint').textContent = '集計取得失敗: ' + e.message;
      }
    }

    function renderTiles(d) {
      function tile(label, count, cls, preset) {
        const onclick = preset
          ? 'onclick="navigate(\'search\', {preset:\'' + preset + '\'})"'
          : '';
        const cursor = preset ? '' : 'cursor:default;';
        return '<a class="dash-tile ' + cls + '" ' + onclick + ' style="' + cursor + '">' +
          '<div class="label">' + label + '</div>' +
          '<div><span class="num">' + count + '</span><span class="unit">件</span></div>' +
          '</a>';
      }
      document.getElementById('dashTiles').innerHTML =
        tile('🚨 納期遅延', d.overdue.count, 'danger', 'overdue') +
        tile('📅 今週入荷予定', d.thisWeek.count, 'info', 'this_week') +
        tile('✅ 本日仕上がり', d.todayFinish.count, 'success', 'today_finish') +
        tile('📂 進行中案件', d.projects.length, 'muted', '');
    }

    function renderProjects(projects) {
      const el = document.getElementById('projectList');
      if (!projects.length) {
        el.innerHTML = '<span class="small">案件タグ（用途）が設定された未完了の発注はありません。</span>';
        return;
      }
      el.innerHTML = projects.map(function(p) {
        const segs = ['発注済','納期回答済','入荷済'].map(function(s) {
          const n = p.byStatus[s] || 0;
          if (!n) return '';
          const w = (n / p.total * 100).toFixed(1);
          return '<span class="' + PROJECT_BAR_CLASS[s] + '" style="width:' + w + '%" title="' + s + ' ' + n + '件"></span>';
        }).join('');
        const usageEsc = esc(p.usage).replace(/'/g, "\\'");
        return '<div class="project-row" style="cursor:pointer" onclick="navigate(\'search\', {usage:\'' + usageEsc + '\'})" title="クリックでこの案件の明細を表示">' +
          '<div>' +
            '<div class="project-name">' + esc(p.usage) + '</div>' +
            '<div class="project-bar">' + segs + '</div>' +
          '</div>' +
          '<div class="small">' + p.total + ' 明細</div>' +
          '</div>';
      }).join('');
    }


    // ■ ② 新規注文 / 編集 ========================================

    let MASTER_ITEMS_BY_NAME = {};
    let MASTER_SUPPLIER_SET = new Set();
    let MASTER_PERSON_SET = new Set();
    let MASTER_ITEM_SET = new Set();
    let EDIT_ORDER_NUMBER = '';

    function initNewOrder(params) {
      EDIT_ORDER_NUMBER = String((params && params.orderNumber) || '').trim();
      loadMasters();
      if (EDIT_ORDER_NUMBER) {
        enterEditMode();
      } else {
        // 新規モード
        document.getElementById('copyBtn').classList.remove('hidden');
        document.getElementById('editingHeader').classList.add('hidden');
        document.getElementById('saveBtn').textContent = '保存して注文書を発行';
        document.getElementById('orderDate').value = new Date().toISOString().slice(0, 10);
        document.getElementById('itemsBody').innerHTML = '';
        for (let i = 0; i < 5; i++) addRow();
      }
    }

    function addRow(values) {
      const tbody = document.getElementById('itemsBody');
      const tr = document.createElement('tr');
      const v = values || {};
      tr.innerHTML =
        '<td class="num"></td>' +
        '<td><input type="text" class="name" value="' + esc(v.name) + '" placeholder="品名" list="items" autocomplete="off"></td>' +
        '<td><input type="text" class="quantity" value="' + esc(v.quantity) + '" placeholder="例: 8個"></td>' +
        '<td><input type="text" class="unitPrice num" value="' + esc(v.unitPrice) + '" inputmode="decimal"></td>' +
        '<td><input type="text" class="amount num" value="' + esc(v.amount) + '" inputmode="decimal"></td>' +
        '<td><input type="text" class="note" value="' + esc(v.note) + '"></td>' +
        '<td><button type="button" class="ghost small" onclick="removeRow(this)" title="削除">✕</button></td>';
      tbody.appendChild(tr);
      bindAutoAmount(tr);
      bindItemAutofill(tr);
      bindAutoAppend(tr);
      renumber();
    }
    function removeRow(btn) {
      const tr = btn.closest('tr');
      tr.parentNode.removeChild(tr);
      renumber();
    }
    function renumber() {
      document.querySelectorAll('#itemsBody tr').forEach(function(tr, i) {
        tr.firstElementChild.textContent = i + 1;
      });
    }
    function bindAutoAmount(tr) {
      const q = tr.querySelector('.quantity');
      const p = tr.querySelector('.unitPrice');
      const a = tr.querySelector('.amount');
      function recalc() {
        if (a.dataset.manual === '1') return;
        const qn = parseFloat(String(q.value).replace(/[^0-9.]/g, ''));
        const pn = parseFloat(p.value);
        if (!isNaN(qn) && !isNaN(pn)) a.value = Math.round(qn * pn);
      }
      q.addEventListener('input', recalc);
      p.addEventListener('input', recalc);
      a.addEventListener('input', function() { a.dataset.manual = '1'; });
    }
    function bindItemAutofill(tr) {
      const nameInput = tr.querySelector('.name');
      nameInput.addEventListener('change', function() {
        const m = MASTER_ITEMS_BY_NAME[nameInput.value];
        if (!m) return;
        const p = tr.querySelector('.unitPrice');
        if (m.unitPrice && !p.value) {
          p.value = m.unitPrice;
          p.dispatchEvent(new Event('input'));
        }
      });
    }
    function bindAutoAppend(tr) {
      const nameInput = tr.querySelector('.name');
      let triggered = false;
      nameInput.addEventListener('input', function() {
        if (triggered) return;
        if (!nameInput.value.trim()) return;
        const tbody = document.getElementById('itemsBody');
        if (tr !== tbody.lastElementChild) return;
        triggered = true;
        addRow();
      });
    }

    function setHeader(h) {
      document.getElementById('supplier').value = h.supplier || '';
      document.getElementById('orderDate').value = h.orderDate || new Date().toISOString().slice(0,10);
      document.getElementById('deliveryDate').value = /^\d{4}-\d{2}-\d{2}$/.test(h.deliveryDate || '') ? h.deliveryDate : '';
      document.getElementById('person').value = h.person || '';
      document.getElementById('usage').value = h.usage || '';
      document.getElementById('internalMemo').value = h.internalMemo || '';
    }

    function collectOrder() {
      return {
        header: {
          supplier: document.getElementById('supplier').value.trim(),
          orderDate: document.getElementById('orderDate').value,
          deliveryDate: document.getElementById('deliveryDate').value,
          person: document.getElementById('person').value.trim(),
          usage: document.getElementById('usage').value.trim(),
          internalMemo: document.getElementById('internalMemo').value.trim()
        },
        items: Array.from(document.querySelectorAll('#itemsBody tr')).map(function(tr) {
          return {
            name: tr.querySelector('.name').value.trim(),
            quantity: tr.querySelector('.quantity').value.trim(),
            unitPrice: tr.querySelector('.unitPrice').value.trim(),
            amount: tr.querySelector('.amount').value.trim(),
            note: tr.querySelector('.note').value.trim()
          };
        }).filter(function(it) { return it.name; })
      };
    }

    async function save() {
      const payload = collectOrder();
      if (!payload.header.supplier) return toast('仕入先名を入力してください', true);
      if (payload.items.length === 0) return toast('明細を1行以上入力してください', true);
      const btn = document.getElementById('saveBtn');
      btn.disabled = true;
      try {
        let resultOrderNumber;
        if (EDIT_ORDER_NUMBER) {
          const r = await call('updateOrder', EDIT_ORDER_NUMBER, payload.header, payload.items);
          resultOrderNumber = r.orderNumber;
          toast('更新しました 発注番号: ' + resultOrderNumber);
        } else {
          const r = await call('saveOrder', payload.header, payload.items);
          resultOrderNumber = r.orderNumber;
          toast('保存しました 発注番号: ' + resultOrderNumber);
        }
        await maybePromptMasterAdd(payload);
        navigate('order_pdf', { orderNumber: resultOrderNumber });
      } catch (e) {
        btn.disabled = false;
        toast('エラー: ' + (e && e.message ? e.message : e), true);
      }
    }

    function maybePromptMasterAdd(payload) {
      const newSuppliers = payload.header.supplier && !MASTER_SUPPLIER_SET.has(payload.header.supplier) ? [payload.header.supplier] : [];
      const newPersons = payload.header.person && !MASTER_PERSON_SET.has(payload.header.person) ? [payload.header.person] : [];
      const seen = {};
      const newItems = [];
      payload.items.forEach(function(it) {
        const n = it.name;
        if (n && !MASTER_ITEM_SET.has(n) && !seen[n]) { seen[n] = true; newItems.push(n); }
      });
      if (!newSuppliers.length && !newPersons.length && !newItems.length) return Promise.resolve();

      return new Promise(function(resolve) {
        function cb(items, kind) {
          return items.map(function(name) {
            return '<label style="display:block; margin:4px 0">' +
              '<input type="checkbox" data-kind="' + kind + '" value="' + esc(name) + '" checked> ' +
              esc(name) + '</label>';
          }).join('');
        }
        const html =
          '<p class="small">入力された値のうちマスタに無いものがあります。<br>マスタに追加すると次回から候補表示されます。</p>' +
          (newSuppliers.length ? '<h4 style="margin:12px 0 4px">仕入先マスタへ</h4>' + cb(newSuppliers, 'supplier') : '') +
          (newPersons.length ? '<h4 style="margin:12px 0 4px">担当者マスタへ</h4>' + cb(newPersons, 'person') : '') +
          (newItems.length ? '<h4 style="margin:12px 0 4px">品名マスタへ</h4>' + cb(newItems, 'item') : '') +
          '<div class="modal-footer" style="margin-top:16px; padding:0; border:none">' +
            '<button class="ghost" onclick="window.__masterSkip()">スキップ</button>' +
            '<button class="primary" onclick="window.__masterApply()">追加して続行</button>' +
          '</div>';
        const body = openModal(html, 'マスタに追加しますか？');
        window.__masterSkip = function() { closeModal(); resolve(); };
        window.__masterApply = async function() {
          const checks = body.querySelectorAll('input[type=checkbox]:checked');
          const sel = { suppliers: [], persons: [], items: [] };
          checks.forEach(function(c) {
            const k = c.dataset.kind;
            if (k === 'supplier') sel.suppliers.push(c.value);
            else if (k === 'person') sel.persons.push(c.value);
            else if (k === 'item') sel.items.push(c.value);
          });
          try {
            const r = await call('addToMasters', sel);
            toast('マスタへ追加: 仕入先' + r.suppliers + '/担当' + r.persons + '/品名' + r.items + '件');
          } catch (e) { toast('マスタ追加でエラー: ' + e.message, true); }
          closeModal();
          resolve();
        };
      });
    }

    async function loadMasters() {
      try {
        const m = await call('getMasters');
        const supNames = m.suppliers.map(function(s) { return s.name; });
        const perNames = m.persons.map(function(p) { return p.name; });
        const itemNames = m.items.map(function(i) { return i.name; });
        document.getElementById('suppliers').innerHTML = supNames.map(function(n) { return '<option value="' + esc(n) + '">'; }).join('');
        document.getElementById('persons').innerHTML = perNames.map(function(n) { return '<option value="' + esc(n) + '">'; }).join('');
        document.getElementById('items').innerHTML = itemNames.map(function(n) { return '<option value="' + esc(n) + '">'; }).join('');
        MASTER_ITEMS_BY_NAME = m.items.reduce(function(acc, it) { acc[it.name] = it; return acc; }, {});
        MASTER_SUPPLIER_SET = new Set(supNames);
        MASTER_PERSON_SET = new Set(perNames);
        MASTER_ITEM_SET = new Set(itemNames);
      } catch (e) { /* マスタ未整備時は無視 */ }
    }

    async function openCopyPicker() {
      const body = openModal('<div class="small">読み込み中...</div>', '過去注文から複製');
      try {
        const list = await call('getRecentOrders', 50);
        if (!list.length) { body.innerHTML = '<p class="small">過去の注文がまだありません。</p>'; return; }
        body.innerHTML =
          '<input type="text" id="copyFilter" placeholder="絞り込み（仕入先・用途など）" autofocus>' +
          '<div class="table-wrap" style="margin-top:10px"><table>' +
            '<thead><tr><th>発注日</th><th>発注番号</th><th>仕入先</th><th>担当</th><th>用途</th><th>明細数</th><th></th></tr></thead>' +
            '<tbody id="copyRows">' +
            list.map(function(o) {
              return '<tr>' +
                '<td>' + esc(o.orderDate) + '</td>' +
                '<td>' + esc(o.orderNumber) + '</td>' +
                '<td>' + esc(o.supplier) + '</td>' +
                '<td>' + esc(o.person) + '</td>' +
                '<td>' + esc(o.usage) + '</td>' +
                '<td class="num">' + o.itemCount + '</td>' +
                '<td><button class="primary small" onclick="pickCopy(\'' + esc(o.orderNumber) + '\')">この内容で複製</button></td>' +
                '</tr>';
            }).join('') +
            '</tbody></table></div>';
        document.getElementById('copyFilter').addEventListener('input', function(e) {
          const q = e.target.value.toLowerCase();
          document.querySelectorAll('#copyRows tr').forEach(function(tr) {
            tr.style.display = tr.textContent.toLowerCase().indexOf(q) >= 0 ? '' : 'none';
          });
        });
      } catch (e) { body.innerHTML = '<p class="error">' + esc(e.message) + '</p>'; }
    }
    async function pickCopy(orderNumber) {
      try {
        const o = await call('getOrder', orderNumber);
        if (!o) { toast('元の注文が見つかりませんでした', true); return; }
        setHeader({
          supplier: o.supplier,
          orderDate: new Date().toISOString().slice(0,10),
          deliveryDate: '',
          person: o.person,
          usage: o.usage,
          internalMemo: o.internalMemo
        });
        document.getElementById('itemsBody').innerHTML = '';
        o.items.forEach(function(it) { addRow({ name: it.name, quantity: it.quantity, unitPrice: it.unitPrice, amount: it.amount, note: it.note }); });
        addRow();
        closeModal();
        toast('複製: ' + orderNumber + ' の内容を読み込みました');
      } catch (e) { toast('エラー: ' + e.message, true); }
    }

    async function enterEditMode() {
      const orderNumber = EDIT_ORDER_NUMBER;
      if (!orderNumber) return;
      document.getElementById('copyBtn').classList.add('hidden');
      document.getElementById('editingHeader').classList.remove('hidden');
      document.getElementById('editingNo').textContent = orderNumber;
      document.getElementById('saveBtn').textContent = '更新する';
      try {
        const o = await call('getOrder', orderNumber);
        if (!o) {
          toast('注文 ' + orderNumber + ' は見つかりませんでした（削除/取消の可能性）。新規入力に戻ります', true);
          setTimeout(function() { navigate('new_order'); }, 1500);
          return;
        }
        setHeader({
          supplier: o.supplier,
          orderDate: o.orderDate,
          deliveryDate: o.deliveryDate,
          person: o.person,
          usage: o.usage,
          internalMemo: o.internalMemo
        });
        document.getElementById('itemsBody').innerHTML = '';
        o.items.forEach(function(it) { addRow({ name: it.name, quantity: it.quantity, unitPrice: it.unitPrice, amount: it.amount, note: it.note }); });
      } catch (e) { toast('エラー: ' + e.message, true); }
    }


    // ■ ③ 注文書プレビュー =======================================

    let CURRENT_ORDER_NUMBER = '';

    async function initOrderPdf(params) {
      CURRENT_ORDER_NUMBER = String((params && params.orderNumber) || '').trim();
      if (!CURRENT_ORDER_NUMBER) {
        document.getElementById('orderDoc').innerHTML = '<p class="error">発注番号が指定されていません。</p>';
        return;
      }
      try {
        const o = await call('getOrder', CURRENT_ORDER_NUMBER);
        if (!o) { document.getElementById('orderDoc').innerHTML = '<p class="error">見つかりませんでした。</p>'; return; }
        document.getElementById('editLink').onclick = function(e) { e.preventDefault(); navigate('new_order', { orderNumber: CURRENT_ORDER_NUMBER }); };
        const isCanceled = o.items.some(function(it) { return it.status === '取消'; });
        document.getElementById('cancelBtn').style.display = isCanceled ? 'none' : '';
        document.getElementById('restoreBtn').style.display = isCanceled ? '' : 'none';
        renderOrderDoc(o);
      } catch (e) { document.getElementById('orderDoc').innerHTML = '<p class="error">' + esc(e.message) + '</p>'; }
    }

    function renderOrderDoc(o) {
      const MIN_ROWS = 14;
      const pad = Math.max(0, MIN_ROWS - o.items.length);
      const rows = o.items.map(function(it) {
        return '<tr>' +
          '<td>' + esc(it.name) + '</td>' +
          '<td class="num">' + esc(it.quantity) + '</td>' +
          '<td class="num">' + esc(it.unitPrice) + '</td>' +
          '<td class="num">' + esc(it.amount) + '</td>' +
          '<td>' + esc(it.note) + '</td>' +
          '</tr>';
      }).join('');
      let padRows = '';
      for (let i = 0; i < pad; i++) padRows += '<tr><td>&nbsp;</td><td></td><td></td><td></td><td></td></tr>';

      document.getElementById('orderDoc').innerHTML =
        '<div class="doc-title">注　文　書</div>' +
        '<div class="doc-head">' +
          '<div><div class="supplier-box">' + esc(o.supplier) + ' 御中</div></div>' +
          '<div class="issuer-box">' +
            '<div><b>永晃産業株式会社</b></div>' +
            '<div>〒571-0017 大阪府門真市四宮6丁目7-1</div>' +
            '<div>TEL: 072(885)3031　FAX: 072(885)3033</div>' +
          '</div>' +
        '</div>' +
        '<table class="meta-table">' +
          '<tr><td class="label">発注番号</td><td>' + esc(o.orderNumber) + '</td>' +
              '<td class="label">発注日</td><td>' + esc(formatJpDate(o.orderDate)) + '</td></tr>' +
          '<tr><td class="label">納期</td><td>' + esc(formatJpDate(o.deliveryDate)) + '</td>' +
              '<td class="label">担当者</td><td>' + esc(o.person) + '</td></tr>' +
        '</table>' +
        '<table class="items-table">' +
          '<thead><tr><th>品　名</th><th style="width:7em">数量</th><th style="width:7em">単価</th><th style="width:8em">金額</th><th>備考</th></tr></thead>' +
          '<tbody>' + rows + padRows + '</tbody>' +
        '</table>' +
        '<div class="db-notice db-only">' +
          '【社内情報 / この枠は印刷されません】用途: ' + esc(o.usage) + ' ／ 社内メモ: ' + esc(o.internalMemo) +
        '</div>';
    }

    async function cancelThis() {
      if (!confirm('発注番号 ' + CURRENT_ORDER_NUMBER + ' を取消します。よろしいですか？')) return;
      try { await call('cancelOrder', CURRENT_ORDER_NUMBER, ''); toast('取消しました'); initOrderPdf({orderNumber: CURRENT_ORDER_NUMBER}); }
      catch (e) { toast('エラー: ' + e.message, true); }
    }
    async function restoreThis() {
      if (!confirm('発注番号 ' + CURRENT_ORDER_NUMBER + ' の取消を解除します。よろしいですか？')) return;
      try { await call('restoreOrder', CURRENT_ORDER_NUMBER); toast('復活しました'); initOrderPdf({orderNumber: CURRENT_ORDER_NUMBER}); }
      catch (e) { toast('エラー: ' + e.message, true); }
    }


    // ■ ④ 検索 ===================================================

    let SEARCH_PRESET = '';
    let SEARCH_USAGE_INITIAL = '';

    function initSearch(params) {
      SEARCH_PRESET = String((params && params.preset) || '').trim();
      SEARCH_USAGE_INITIAL = String((params && params.usage) || '').trim();
      // プリセットや用途指定があれば反映＆即検索
      if (SEARCH_USAGE_INITIAL) document.getElementById('searchUsage').value = SEARCH_USAGE_INITIAL;
      if (SEARCH_PRESET) {
        document.getElementById('presetLabel').textContent = '絞り込み: ' + (PRESET_LABELS[SEARCH_PRESET] || SEARCH_PRESET);
        document.getElementById('searchSource').value = 'orders';
      }
      if (SEARCH_PRESET || SEARCH_USAGE_INITIAL) runSearch();
    }

    async function runSearch() {
      const q = {
        text: document.getElementById('searchText').value,
        supplier: document.getElementById('searchSupplier').value,
        usage: document.getElementById('searchUsage').value,
        dateFrom: document.getElementById('searchDateFrom').value,
        dateTo: document.getElementById('searchDateTo').value,
        status: document.getElementById('searchStatus').value,
        // プリセット検索は新規発注のみが対象
        source: SEARCH_PRESET ? 'orders' : document.getElementById('searchSource').value,
        preset: SEARCH_PRESET
      };
      document.getElementById('searchSummary').textContent = '検索中...';
      try {
        const res = await call('searchAll', q);
        renderSearchResults(res);
      } catch (e) {
        document.getElementById('searchSummary').textContent = 'エラー: ' + e.message;
      }
    }

    function renderSearchResults(res) {
      document.getElementById('searchSummary').textContent =
        res.total + ' 件' + (res.total >= res.limit ? '（上限' + res.limit + '件で打ち切り）' : '');
      if (res.rows.length === 0) {
        document.getElementById('searchRows').innerHTML =
          '<tr><td colspan="13" class="small" style="text-align:center; padding:32px">該当なし</td></tr>';
        return;
      }
      document.getElementById('searchRows').innerHTML = res.rows.map(function(r) {
        const statusCls = STATUS_CLASS[r.status] || '';
        const statusHtml = r.status ? '<span class="badge ' + statusCls + '">' + esc(r.status) + '</span>' : '';
        const srcCls = r.source === 'legacy' ? 'badge-legacy' : 'badge-new';
        const srcLabel = r.source === 'legacy' ? '過去' : '新規';
        const rowCls = r.status === '取消' ? 'row-canceled' : '';
        return '<tr class="' + rowCls + '">' +
          '<td>' + searchOrderLink(r) + '</td>' +
          '<td>' + esc(r.supplier) + '</td>' +
          '<td>' + esc(r.name) + '</td>' +
          '<td class="num">' + esc(r.quantity) + '</td>' +
          '<td>' + esc(r.orderDate) + '</td>' +
          '<td>' + esc(r.deliveryDate) + '</td>' +
          '<td>' + esc(r.plannedDelivery) + '</td>' +
          '<td>' + esc(r.arrivalDate) + '</td>' +
          '<td>' + esc(r.finishDate) + '</td>' +
          '<td>' + statusHtml + '</td>' +
          '<td>' + esc(r.usage) + '</td>' +
          '<td><span class="badge ' + srcCls + '">' + srcLabel + '</span></td>' +
          '<td>' + searchActionsHtml(r) + '</td>' +
          '</tr>';
      }).join('');
    }

    function searchOrderLink(r) {
      if (r.source !== 'orders' || !r.orderNumber) return esc(r.orderNumber || '');
      return '<a href="javascript:void(0)" onclick="navigate(\'order_pdf\', {orderNumber:\'' + esc(r.orderNumber) + '\'})">' + esc(r.orderNumber) + '</a>';
    }
    function searchActionsHtml(r) {
      if (r.source !== 'orders' || !r.orderNumber) return '';
      const isCancel = r.status === '取消';
      return '<div class="row-actions">' +
        '<button class="ghost" onclick="navigate(\'new_order\', {orderNumber:\'' + esc(r.orderNumber) + '\'})" title="編集">✏️</button>' +
        (isCancel
          ? '<button class="ghost" onclick="cancelOneSearch(\'' + esc(r.orderNumber) + '\', true)" title="復活">↩</button>'
          : '<button class="danger" onclick="cancelOneSearch(\'' + esc(r.orderNumber) + '\', false)" title="取消">🚫</button>') +
        '</div>';
    }
    async function cancelOneSearch(no, restore) {
      const msg = (restore ? no + ' の取消を解除します' : no + ' を取消します') + '。よろしいですか？';
      if (!confirm(msg)) return;
      try {
        await call(restore ? 'restoreOrder' : 'cancelOrder', no, '');
        toast(restore ? '復活しました' : '取消しました');
        runSearch();
      } catch (e) { toast('エラー: ' + e.message, true); }
    }

    function clearSearch() {
      ['searchText','searchSupplier','searchUsage','searchDateFrom','searchDateTo'].forEach(function(id) { document.getElementById(id).value = ''; });
      document.getElementById('searchStatus').value = '';
      document.getElementById('searchSource').value = 'both';
      document.getElementById('searchSummary').textContent = '';
      document.getElementById('presetLabel').textContent = '';
      SEARCH_PRESET = '';
      SEARCH_USAGE_INITIAL = '';
      document.getElementById('searchRows').innerHTML =
        '<tr><td colspan="13" class="small" style="text-align:center; padding:32px">条件を入力して「検索」を押してください。</td></tr>';
      document.getElementById('searchText').focus();
    }


    // ■ ⑤ 納品日登録 =============================================

    let DELIVERY_CURRENT = null;

    function initDelivery() {
      // 何もしない（ユーザー入力待ち）
    }

    async function loadOrderForDelivery() {
      const n = document.getElementById('lookupOrderNumber').value.trim();
      if (!n) return toast('発注番号を入力してください', true);
      try {
        const o = await call('getOrder', n);
        if (!o) return toast('見つかりませんでした', true);
        DELIVERY_CURRENT = o;
        document.getElementById('deliveryDetail').classList.remove('hidden');
        document.getElementById('deliveryTitle').textContent = o.supplier + ' 御中  /  発注番号 ' + o.orderNumber;
        document.getElementById('deliveryMeta').textContent =
          '発注日: ' + o.orderDate + '　納期: ' + formatJpDate(o.deliveryDate) + '　担当: ' + o.person +
          (o.usage ? '　用途: ' + o.usage : '');
        document.getElementById('deliveryPdfLink').onclick = function(e) {
          e.preventDefault(); navigate('order_pdf', { orderNumber: o.orderNumber });
        };
        document.getElementById('deliveryRows').innerHTML = o.items.map(function(it) {
          const cls = STATUS_CLASS[it.status] || '';
          return '<tr data-line="' + it.lineNumber + '">' +
            '<td>' + it.lineNumber + '</td>' +
            '<td>' + esc(it.name) + '</td>' +
            '<td class="num">' + esc(it.quantity) + '</td>' +
            '<td><input type="date" class="plannedDelivery" value="' + esc(it.plannedDelivery) + '"></td>' +
            '<td><input type="date" class="arrivalDate" value="' + esc(it.arrivalDate) + '"></td>' +
            '<td><input type="date" class="finishDate" value="' + esc(it.finishDate) + '"></td>' +
            '<td><span class="badge ' + cls + '">' + esc(it.status) + '</span></td>' +
            '<td><button class="primary small" onclick="saveDeliveryRow(this)">更新</button></td>' +
            '</tr>';
        }).join('');
      } catch (e) { toast(e.message, true); }
    }

    async function saveDeliveryRow(btn) {
      const tr = btn.closest('tr');
      btn.disabled = true;
      try {
        await call('updateDelivery', {
          orderNumber: DELIVERY_CURRENT.orderNumber,
          lineNumber: Number(tr.dataset.line),
          plannedDelivery: tr.querySelector('.plannedDelivery').value,
          arrivalDate: tr.querySelector('.arrivalDate').value,
          finishDate: tr.querySelector('.finishDate').value
        });
        toast('更新しました (行: ' + tr.dataset.line + ')');
        loadOrderForDelivery();
      } catch (e) {
        btn.disabled = false;
        toast(e.message, true);
      }
    }


    // ■ 起動 =====================================================

    // data-nav 属性付き要素は navigate() に流す
    document.querySelectorAll('[data-nav]').forEach(function(el) {
      el.style.cursor = 'pointer';
      el.addEventListener('click', function(e) { e.preventDefault(); navigate(el.dataset.nav); });
    });

    document.getElementById('lookupOrderNumber') && document.getElementById('lookupOrderNumber').addEventListener('keydown', function(e) {
      if (e.key === 'Enter') loadOrderForDelivery();
    });
    document.querySelectorAll('section[data-page="search"] input').forEach(function(el) {
      el.addEventListener('keydown', function(e) { if (e.key === 'Enter') runSearch(); });
    });

    (function bootstrap() {
      const initialPage = (INITIAL_PARAMS && INITIAL_PARAMS.page) || 'menu';
      const safePage = ['menu','new_order','order_pdf','search','delivery'].indexOf(initialPage) >= 0 ? initialPage : 'menu';
      showPage(safePage);
      const init = PAGE_INITS[safePage];
      if (init) init(INITIAL_PARAMS);
    })();
  </script>
</body>
</html>

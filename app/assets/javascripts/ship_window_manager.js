(function () {
  function parseData() {
    var node = document.getElementById("program-data");
    return node ? JSON.parse(node.textContent) : null;
  }

  function formatDate(value) {
    var parts = value.split("-");
    return parts.length === 3 ? parts[1] + "/" + parts[2] + "/" + parts[0] : value;
  }

  function nextDay(value) {
    var date = new Date(value + "T00:00:00");
    date.setDate(date.getDate() + 1);
    return date.toISOString().slice(0, 10);
  }

  function monthClasses(items) {
    var classes = {};
    items.forEach(function (item) { classes[item.class_name] = true; });
    return Object.keys(classes).sort();
  }

  document.addEventListener("DOMContentLoaded", function () {
    Array.prototype.forEach.call(document.querySelectorAll(".swm-tab"), function (tab) {
      tab.addEventListener("click", function () {
        Array.prototype.forEach.call(document.querySelectorAll(".swm-tab"), function (candidate) {
          candidate.classList.toggle("is-active", candidate === tab);
        });
        Array.prototype.forEach.call(document.querySelectorAll(".tab-panel"), function (panel) {
          panel.classList.toggle("is-active", panel.id === tab.getAttribute("data-tab-target"));
        });
      });
    });

    var payload = parseData();
    if (!payload) return;

    var ranges = payload.ranges.slice();
    var selectedIndex = 0;
    var query = "";
    var classFilter = "";
    var rangeList = document.getElementById("range-list");
    var detailPanel = document.getElementById("detail-panel");
    var rangesJson = document.getElementById("ranges-json");
    var addButton = document.getElementById("add-range");
    var form = document.getElementById("ship-window-form");

    function selectedRange() {
      return ranges[selectedIndex];
    }

    function visibleItems() {
      var normalized = query.trim().toLowerCase();
      return payload.items.filter(function (item) {
        var matchesClass = classFilter === "" || item.class_name === classFilter;
        var haystack = [item.class_name, item.item_code, item.description].join(" ").toLowerCase();
        return matchesClass && (normalized === "" || haystack.indexOf(normalized) !== -1);
      });
    }

    function syncJson() {
      rangesJson.value = JSON.stringify(ranges.map(function (range) {
        return {
          id: range.id,
          start_date: range.start_date,
          end_date: range.end_date,
          item_ids: range.item_ids.map(Number)
        };
      }));
    }

    function render() {
      syncJson();
      renderRangeList();
      renderDetail();
    }

    function renderRangeList() {
      rangeList.innerHTML = "";
      ranges.forEach(function (range, index) {
        var card = document.createElement("article");
        card.className = "range-card" + (index === selectedIndex ? " is-active" : "");

        var main = document.createElement("div");
        main.className = "range-card-main";
        main.innerHTML = [
          '<div class="range-card-title"><span>Ship Window ' + (index + 1) + '</span><span>' + range.item_ids.length + ' items</span></div>',
          '<div class="range-card-meta">' + formatDate(range.start_date) + " - " + formatDate(range.end_date) + '</div>',
          '<div class="range-card-meta">Applies to: ' + range.item_ids.length + ' items</div>'
        ].join("");
        main.addEventListener("click", function () {
          selectedIndex = index;
          render();
        });

        var actions = document.createElement("div");
        actions.className = "range-actions";
        actions.innerHTML = '<button type="button" class="link-button">Edit items</button><button type="button" class="secondary-button">Duplicate</button><button type="button" class="danger-button">Delete</button>';
        actions.children[0].addEventListener("click", function () {
          selectedIndex = index;
          render();
        });
        actions.children[1].addEventListener("click", function () {
          ranges.splice(index + 1, 0, {
            id: null,
            start_date: range.start_date,
            end_date: range.end_date,
            item_ids: range.item_ids.slice()
          });
          selectedIndex = index + 1;
          render();
        });
        actions.children[2].addEventListener("click", function () {
          if (!window.confirm("Delete this ship window range?")) return;
          ranges.splice(index, 1);
          selectedIndex = Math.max(0, Math.min(selectedIndex, ranges.length - 1));
          render();
        });

        card.appendChild(main);
        card.appendChild(actions);
        rangeList.appendChild(card);
      });
    }

    function renderDetail() {
      if (ranges.length === 0) {
        detailPanel.innerHTML = '<p class="empty-detail">Add a ship window to start assigning items.</p>';
        return;
      }

      var range = selectedRange();
      var classes = monthClasses(payload.items);
      var filteredItems = visibleItems();
      var selected = {};
      range.item_ids.forEach(function (id) { selected[Number(id)] = true; });

      detailPanel.innerHTML = [
        '<div class="detail-heading"><h2>Ship Window ' + (selectedIndex + 1) + '</h2><span class="count-text"><strong id="assigned-count">' + range.item_ids.length + '</strong> assigned items</span></div>',
        '<div class="field-grid">',
        '<div class="field"><label for="load-start">Load Start</label><input id="load-start" type="date" value="' + range.start_date + '" min="' + payload.program.ship_start_date + '" max="' + payload.program.ship_end_date + '"></div>',
        '<div class="field"><label for="load-end">Load End</label><input id="load-end" type="date" value="' + range.end_date + '" min="' + payload.program.ship_start_date + '" max="' + payload.program.ship_end_date + '"></div>',
        '</div>',
        '<div class="toolbar">',
        '<input id="item-search" type="search" placeholder="Search items" value="' + query.replace(/"/g, "&quot;") + '">',
        '<select id="class-filter"><option value="">All classes</option>' + classes.map(function (name) { return '<option value="' + name + '"' + (name === classFilter ? " selected" : "") + ">" + name + "</option>"; }).join("") + '</select>',
        '<button type="button" id="select-visible" class="secondary-button">Select all visible</button>',
        '<button type="button" id="clear-selection" class="secondary-button">Clear selection</button>',
        '</div>',
        '<div class="item-table-wrap"><table><thead><tr><th class="checkbox-cell"></th><th>Class</th><th>Item Code</th><th>Item</th></tr></thead><tbody id="item-rows"></tbody></table></div>'
      ].join("");

      var tbody = document.getElementById("item-rows");
      filteredItems.forEach(function (item) {
        var row = document.createElement("tr");
        row.innerHTML = [
          '<td class="checkbox-cell"><input type="checkbox" data-item-id="' + item.id + '"' + (selected[item.id] ? " checked" : "") + "></td>",
          "<td>" + item.class_name + "</td>",
          "<td>" + item.item_code + "</td>",
          "<td>" + item.description + "</td>"
        ].join("");
        tbody.appendChild(row);
      });

      bindDetailEvents();
    }

    function bindDetailEvents() {
      var range = selectedRange();
      document.getElementById("load-start").addEventListener("change", function (event) {
        range.start_date = event.target.value;
        render();
      });
      document.getElementById("load-end").addEventListener("change", function (event) {
        range.end_date = event.target.value;
        render();
      });
      document.getElementById("item-search").addEventListener("input", function (event) {
        query = event.target.value;
        render();
      });
      document.getElementById("class-filter").addEventListener("change", function (event) {
        classFilter = event.target.value;
        render();
      });
      document.getElementById("select-visible").addEventListener("click", function () {
        var ids = {};
        range.item_ids.forEach(function (id) { ids[Number(id)] = true; });
        visibleItems().forEach(function (item) { ids[item.id] = true; });
        range.item_ids = Object.keys(ids).map(Number).sort(function (a, b) { return a - b; });
        render();
      });
      document.getElementById("clear-selection").addEventListener("click", function () {
        range.item_ids = [];
        render();
      });
      Array.prototype.forEach.call(detailPanel.querySelectorAll("input[type=checkbox][data-item-id]"), function (checkbox) {
        checkbox.addEventListener("change", function (event) {
          var id = Number(event.target.getAttribute("data-item-id"));
          if (event.target.checked && range.item_ids.indexOf(id) === -1) {
            range.item_ids.push(id);
          } else if (!event.target.checked) {
            range.item_ids = range.item_ids.filter(function (itemId) { return itemId !== id; });
          }
          range.item_ids.sort(function (a, b) { return a - b; });
          syncJson();
          document.getElementById("assigned-count").textContent = range.item_ids.length;
          renderRangeList();
        });
      });
    }

    addButton.addEventListener("click", function () {
      var startDate = payload.program.ship_start_date;
      if (ranges.length > 0) {
        var latestEnd = ranges.map(function (range) { return range.end_date; }).sort().pop();
        var candidate = nextDay(latestEnd);
        startDate = candidate <= payload.program.ship_end_date ? candidate : payload.program.ship_end_date;
      }
      ranges.push({
        id: null,
        start_date: startDate,
        end_date: payload.program.ship_end_date,
        item_ids: []
      });
      selectedIndex = ranges.length - 1;
      query = "";
      classFilter = "";
      render();
    });

    form.addEventListener("submit", syncJson);
    render();
  });
})();

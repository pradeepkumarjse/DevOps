const now = new Date();

// Format: YYYY-MM-DD
function formatYYYYMMDD(date) {
    return date.toISOString().split('T')[0];
}

// Format: MM/YYYY
function formatMMYYYY(date) {
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const year = date.getFullYear();
    return ${month}/${year};
}

// Today
const currentDate = formatYYYYMMDD(now);

// Tomorrow
const tomorrow = new Date(now);
tomorrow.setDate(now.getDate() + 1);
const currentDatePlus1 = formatYYYYMMDD(tomorrow);

// MM/YYYY
const monthYear = formatMMYYYY(now)


const payload = {
    "date": monthYear,
    "date_from": currentDate,
    "date_to": currentDatePlus1
};

request.body = JSON.stringify(payload);

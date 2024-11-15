const parametersList = [
	{
		name: "living_index",
		label: "Плотность застройки",
		title:
			"Чем ниже значение индекса тем плотнее застройка с учётом этажности.",
	},
	{
		name: "kindergarten_index",
		label: "Доступность детских садов",
		title:
			"Чем выше значение индекса тем больше детских садов в радиусе доступности (до 1 км, до 10 минут пешком). Чем ближе объект, тем больше его вклад в значение индекса.",
	},
	{
		name: "school_index",
		label: "Доступность школ",
		title:
			"Чем выше значение индекса тем больше школ в радиусе доступности (до 1 км, до 10 минут пешком). Чем ближе объект, тем больше его вклад в значение индекса.",
	},
	{
		name: "transport_index",
		label: "Доступность транспорта",
		title:
			"Чем выше значение индекса тем больше маршрутов общественного транспорта в радиусе доступности (до 1 км, до 10 минут пешком). Чем ближе остановка, тем больше его вклад в значение индекса.",
	},
	{
		name: "parking_index",
		label: "Доступность парковок",
		title:
			"Чем выше значение индекса тем больше общественных (без контролируемого доступа) парковок для автотранспорта в радиусе доступности (до 1 км, до 10 минут пешком). Чем ближе парковка, тем больше его вклад в значение индекса.",
	},
	{
		name: "dining_index",
		label: "Доступность баров-ресторанов",
		title:
			"Чем выше значение индекса тем больше кафе,баров,ресторанов и прочих точек питания в радиусе доступности (до 1 км, до 10 минут пешком). Чем ближе объект питания, тем больше его вклад в значение индекса.",
	},
	{
		name: "medical_index",
		label: "Доступность медицины",
		title:
			"Чем выше значение индекса тем больше поликлиник, клиник и больниц в радиусе доступности (до 2 км для клиник и 5 км для больниц, до 30 минут пешком для клиник и 10 минут на авто для больниц). Чем ближе объект и если это больница, то тем больше его вклад в значение индекса.",
	},
	{
		name: "sport_index",
		label: "Доступность спорта",
		title:
			"Чем выше значение индекса тем больше спортивных центров и площадок в радиусе доступности (до 1 км, до 10 минут пешком). Чем ближе объект, тем больше его вклад в значение индекса.",
	},
	{
		name: "park_index",
		label: "Доступность парков/пляжей",
		title:
			"Чем выше значение индекса тем больше парков, ботанических садов и пляжей в радиусе доступности (до 2 км, до 30 минут пешком). Чем ближе парк и больше его площадь, тем больше его вклад в значение индекса.",
	},
	{
		name: "education_index",
		label: "Доступность объектов образования",
		title:
			"Чем выше значение индекса тем больше университетов и колледжей в радиусе доступности (до 2 км, до 30 минут пешком). Чем ближе объект и больше его площадь, тем больше его вклад в значение индекса.",
	},
	{
		name: "industrial_index",
		label: "Производства поблизости",
		title:
			"Чем ниже значение индекса тем больше производственных предприятий (до 2 км, до 30 минут пешком). Чем ближе объект и больше его площадь, тем больше его вклад в значение индекса.",
	},
	{
		name: "shop_food_index",
		label: "Доступность продуктовых магазинов",
		title:
			"Чем выше значение индекса тем больше продовольственных магазинов в радиусе доступности (до 1 км, до 10 минут пешком). Чем ближе объект и больше его площадь, тем больше его вклад в значение индекса.",
	},
	{
		name: "shop_nonfood_index",
		label: "Доступность иных магазинов",
		title:
			"Чем выше значение индекса тем больше непродовольственных магазинов в радиусе доступности (до 1 км, до 10 минут пешком). Чем ближе объект и больше его площадь, тем больше его вклад в значение индекса.",
	},
];

const parametersDefault = [
	{
		id: "0",
		name: "Учитывать все (установка по умолчанию)",
		parameters: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	},
	{
		id: "1",
		name: "Низкая плотность застройки, доступность садов важнее доступности школ",
		parameters: [-1, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	},
	{
		id: "2",
		name: "Высокая плотность застройки и хорошая доступность транспорта",
		parameters: [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	},
	{
		id: "3",
		name: "Низкая плотность застройки, хорошая доступность транспорта и наличие парковок",
		parameters: [-1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
	},
	{
		id: "4",
		name: "Высокая плотность застройки и близко кафэ, рестораны, бары",
		parameters: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
	},
	{
		id: "5",
		name: "Низкая плотность застройки, хорошая доступность транспорта, но наличие баров важнее",
		parameters: [-1, 0, 0, 1, 0, 2, 0, 0, 0, 0, 0, 0, 0],
	},
	{
		id: "6",
		name: "Высокая плотность застройки и хорошая доступность медицины",
		parameters: [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0],
	},
	{
		id: "7",
		name: "Низкая плотность застройки и хорошая доступность спортивных объектов",
		parameters: [-1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0],
	},
	{
		id: "8",
		name: "Высокая плотность застройки, хорошая доступность транспорта и наличие парков",
		parameters: [1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0],
	},
	{
		id: "9",
		name: "Низкая плотность застройки, отсутствие производств",
		parameters: [-1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
	},
];

let cities;
fetch("script/cities.json")
	.then((data) => data.json())
	.then((json) => {
		cities = json;
		console.log(cities);
	});

let tileName = "city_indexes";

let indexParameters = new Map([["city", "Minsk", "building", "*"]]);
let parametersDefaultMapping = new Map();
let indexFilter = [0, 100];
let citiesMapping = new Map();

function createInputs() {
	// Fill select options
	for (city of cities) {
		citiesMapping.set(city.name_en, city.coordinates);
	}
	document.getElementById("city").innerHTML = cities.map((city) =>
		city.name_en === "Minsk"
			? `<option value="${city.name_en}" selected>${city.name_ru}</option>`
			: `<option value="${city.name_en}">${city.name_ru}</option>`,
	);
	for (parameter of parametersDefault) {
		parametersDefaultMapping.set(parameter.id, parameter.parameters);
	}
	document.getElementById("parameters-default").innerHTML =
		parametersDefault.map(
			(parameter) =>
				`<option value="${parameter.id}">${parameter.name}</option>`,
		);
	document.getElementById("parameters-index-importance").innerHTML =
		parametersList
			.map(
				(parameter) =>
					`<p><label for="${parameter.name}_importance" title="${parameter.title}">${parameter.label}:</label><input type="number" id="${parameter.name}_importance" min="-5" max="5" value="1"></p>`,
			)
			.join("");
}

function reloadCityIndex(parameters) {
	// Configure and load tiles
	const urlParameters = Object.entries(Object.fromEntries(parameters))
		.map((e) => e.join("="))
		.join("&");
	if (map.getLayer("city-districts-data")) {
		map.removeLayer("city-districts-data");
	}
	if (map.getSource("city-districts")) {
		map.removeSource("city-districts");
	}
	map.addSource("city-districts", {
		type: "vector",
		url: `http://localhost/tiles/${tileName}?${urlParameters}`,
	});
	map.addLayer({
		id: "city-districts-data",
		type: "fill",
		source: "city-districts",
		"source-layer": tileName,
		paint: {
			"fill-color": [
				"interpolate",
				["linear"],
				["get", "city_index"],
				0,
				["to-color", "#FF0000"],
				100,
				["to-color", "#55ff00"],
			],
			"fill-opacity": 0.6,
		},
	});
	updateValues(indexFilter);
}

function updateArea(e) {
	// Reload tiles for selected region
	if (draw.getAll().features[0]) {
		indexParameters.set(
			"bbox",
			JSON.stringify(draw.getAll().features[0].geometry),
		);
		reloadCityIndex(indexParameters);
	} else {
		indexParameters.delete("bbox");
		reloadCityIndex(indexParameters);
	}
}
function updateIndexes() {
	// Change layer
	tileName = document.getElementById("indexes").value;
	if (tileName === "city_indexes_full") {
		document.getElementById("parameters-building-outer").style =
			"display:none;";
	} else {
		document.getElementById("parameters-building-outer").style =
			"display:block;";
	}
	console.log(tileName);
	reloadCityIndex(indexParameters);
}
function updateParameters() {
	// Read parameters from inputs
	for (parameter of parametersList) {
		indexParameters.set(
			`${parameter.name}_importance`,
			Number.parseInt(
				document.getElementById(`${parameter.name}_importance`).value,
			),
		);
	}
	indexParameters.set("city", document.getElementById("city").value);
	indexParameters.set(
		"building",
		document.getElementById("parameters-building").value,
	);
	console.log(indexParameters);
	reloadCityIndex(indexParameters);
}
function updateDefaultParameters() {
	let i = 0;
	parameters = parametersDefaultMapping.get(
		document.getElementById("parameters-default").value,
	);
	for (parameter of parametersList) {
		document.getElementById(`${parameter.name}_importance`).value =
			parameters[i];
		i++;
	}
	updateParameters();
}
function setCity(feature) {
	let bbox_center;
	// Find city for search result
	if (feature.bbox) {
		// Region
		bbox_center = new maplibregl.LngLatBounds(feature.bbox).getCenter();
	} else if (feature.geometry) {
		// Point
		bbox_center = new maplibregl.LngLat(
			feature.geometry.coordinates[0],
			feature.geometry.coordinates[1],
		);
	} else {
		// From map
		bbox_center = feature;
	}
	let findCity = "";
	let minDistance = 1000000000;
	// Find closest by distance
	for (city of cities) {
		const distance = bbox_center.distanceTo(
			new maplibregl.LngLat(city.coordinates[0], city.coordinates[1]),
		);
		if (distance < minDistance) {
			minDistance = distance;
			findCity = city.name_en;
		}
	}
	if (findCity !== document.getElementById("city").value) {
		document.getElementById("city").value = findCity;
		updateCity();
	}
}
1;
function updateCity(e) {
	// Switch source and fly on teh pam to selected city
	indexParameters.set("city", document.getElementById("city").value);
	map.flyTo({
		center: citiesMapping.get(indexParameters.get("city")),
		essential: true,
	});
	reloadCityIndex(indexParameters);
}
function updateValues(values) {
	// Filter map by selected on legend
	console.log(values);
	map.setFilter("city-districts-data", [
		"all",
		["<=", ["get", "city_index"], Number(values[1])],
		[">=", ["get", "city_index"], Number(values[0])],
	]);
	indexFilter = values;
}

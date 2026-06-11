/**
 * Script para use_figma — crea las 3 pantallas AVOV en una sola llamada MCP.
 *
 * Archivo: kZ0uYN2ZYLFcBjNBGhZEU3
 * Página destino: 📱 Pantallas
 * Componentes locales: 4:2 (Button), 4:4 (Input email), 4:8 (Input pass), 4:12 (MetricCard)
 *
 * Uso en Cursor (cuando haya cuota MCP):
 * /figma-use
 * Ejecuta scripts/figma/complete-pantallas-avov.js en fileKey kZ0uYN2ZYLFcBjNBGhZEU3
 */

await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
await figma.loadFontAsync({ family: 'Inter', style: 'Semi Bold' });
await figma.loadFontAsync({ family: 'Inter', style: 'Bold' });

const COLORS = {
  primary: { r: 30 / 255, g: 58 / 255, b: 95 / 255 },
  background: { r: 245 / 255, g: 247 / 255, b: 250 / 255 },
  surface: { r: 1, g: 1, b: 1 },
  textPrimary: { r: 26 / 255, g: 26 / 255, b: 46 / 255 },
  textSecondary: { r: 107 / 255, g: 114 / 255, b: 128 / 255 },
  accent: { r: 232 / 255, g: 168 / 255, b: 56 / 255 },
  border: { r: 0.85, g: 0.87, b: 0.9 },
  white: { r: 1, g: 1, b: 1 },
};

function removeExistingScreens(page, names) {
  for (const name of names) {
    const node = page.findOne((n) => n.name === name && n.type === 'FRAME');
    if (node) node.remove();
  }
}

function createAppBar(title, options = {}) {
  const { showClose = false } = options;
  const appBar = figma.createFrame();
  appBar.name = 'AppBar';
  appBar.layoutMode = 'HORIZONTAL';
  appBar.primaryAxisSizingMode = 'FIXED';
  appBar.counterAxisSizingMode = 'FIXED';
  appBar.resize(390, 56);
  appBar.paddingLeft = showClose ? 8 : 16;
  appBar.paddingRight = 16;
  appBar.counterAxisAlignItems = 'CENTER';
  appBar.primaryAxisAlignItems = 'SPACE_BETWEEN';
  appBar.itemSpacing = 8;
  appBar.fills = [{ type: 'SOLID', color: COLORS.primary }];

  if (showClose) {
    const closeBtn = figma.createEllipse();
    closeBtn.resize(24, 24);
    closeBtn.fills = [{ type: 'SOLID', color: { ...COLORS.white, a: 0.4 } }];
    appBar.appendChild(closeBtn);
  }

  const appTitle = figma.createText();
  appTitle.fontName = { family: 'Inter', style: 'Semi Bold' };
  appTitle.characters = title;
  appTitle.fontSize = 18;
  appTitle.fills = [{ type: 'SOLID', color: COLORS.white }];
  appBar.appendChild(appTitle);

  if (!showClose) {
    const menu = figma.createEllipse();
    menu.resize(32, 32);
    menu.fills = [{ type: 'SOLID', color: { ...COLORS.white, a: 0.3 } }];
    appBar.appendChild(menu);
  }

  return appBar;
}

function createMobileScreen(name, x) {
  const screen = figma.createFrame();
  screen.name = name;
  screen.resize(390, 844);
  screen.fills = [{ type: 'SOLID', color: COLORS.background }];
  screen.layoutMode = 'VERTICAL';
  screen.primaryAxisSizingMode = 'FIXED';
  screen.counterAxisSizingMode = 'FIXED';
  screen.itemSpacing = 0;
  screen.x = x;
  screen.y = 0;
  return screen;
}

const screensPage = figma.root.children.find((p) => p.name === '📱 Pantallas');
await figma.setCurrentPageAsync(screensPage);
removeExistingScreens(screensPage, ['Login', 'Dashboard / Estudiante', 'Test Vocacional']);

const btnComp = await figma.getNodeByIdAsync('4:2');
const inputEmailComp = await figma.getNodeByIdAsync('4:4');
const inputPassComp = await figma.getNodeByIdAsync('4:8');
const metricComp = await figma.getNodeByIdAsync('4:12');

const createdScreenIds = [];

// --- LOGIN ---
const login = createMobileScreen('Login', 0);
login.layoutMode = 'VERTICAL';
login.primaryAxisAlignItems = 'CENTER';
login.counterAxisAlignItems = 'CENTER';
login.paddingLeft = 24;
login.paddingRight = 24;
login.paddingTop = 48;
login.paddingBottom = 48;

const loginForm = figma.createFrame();
loginForm.name = 'Form';
loginForm.layoutMode = 'VERTICAL';
loginForm.primaryAxisSizingMode = 'AUTO';
loginForm.counterAxisSizingMode = 'FIXED';
loginForm.resize(342, 560);
loginForm.itemSpacing = 16;
loginForm.fills = [];
loginForm.counterAxisAlignItems = 'CENTER';

const loginIcon = figma.createEllipse();
loginIcon.resize(64, 64);
loginIcon.fills = [{ type: 'SOLID', color: COLORS.primary }];

const loginTitle = figma.createText();
loginTitle.fontName = { family: 'Inter', style: 'Bold' };
loginTitle.characters = 'AVOV';
loginTitle.fontSize = 28;
loginTitle.fills = [{ type: 'SOLID', color: COLORS.textPrimary }];

const loginSubtitle = figma.createText();
loginSubtitle.fontName = { family: 'Inter', style: 'Regular' };
loginSubtitle.characters = 'Asistente Virtual de Orientación Vocacional';
loginSubtitle.fontSize = 14;
loginSubtitle.textAlignHorizontal = 'CENTER';
loginSubtitle.resize(300, 40);
loginSubtitle.fills = [{ type: 'SOLID', color: COLORS.textSecondary }];

const email = inputEmailComp.createInstance();
const pass = inputPassComp.createInstance();

const forgot = figma.createText();
forgot.fontName = { family: 'Inter', style: 'Regular' };
forgot.characters = '¿Olvidaste tu contraseña?';
forgot.fontSize = 14;
forgot.fills = [{ type: 'SOLID', color: COLORS.primary }];

const btnRow = figma.createFrame();
btnRow.name = 'Button Row';
btnRow.layoutMode = 'HORIZONTAL';
btnRow.primaryAxisSizingMode = 'AUTO';
btnRow.counterAxisSizingMode = 'FIXED';
btnRow.resize(342, 48);
btnRow.fills = [];
const loginBtn = btnComp.createInstance();
btnRow.appendChild(loginBtn);
loginBtn.layoutSizingHorizontal = 'FILL';

loginForm.appendChild(loginIcon);
loginForm.appendChild(loginTitle);
loginForm.appendChild(loginSubtitle);
loginForm.appendChild(email);
loginForm.appendChild(pass);
loginForm.appendChild(forgot);
loginForm.appendChild(btnRow);
email.layoutSizingHorizontal = 'FILL';
pass.layoutSizingHorizontal = 'FILL';
login.appendChild(loginForm);
createdScreenIds.push({ name: 'Login', id: login.id });

// --- DASHBOARD ESTUDIANTE ---
const dashboard = createMobileScreen('Dashboard / Estudiante', 430);
dashboard.appendChild(createAppBar('Mi panel'));

const dashBody = figma.createFrame();
dashBody.name = 'Body';
dashBody.layoutMode = 'VERTICAL';
dashBody.primaryAxisSizingMode = 'FILL';
dashBody.counterAxisSizingMode = 'FILL';
dashBody.paddingLeft = 16;
dashBody.paddingRight = 16;
dashBody.paddingTop = 16;
dashBody.paddingBottom = 16;
dashBody.itemSpacing = 16;
dashBody.fills = [];

const sectionTitle = figma.createText();
sectionTitle.fontName = { family: 'Inter', style: 'Bold' };
sectionTitle.characters = 'Estado de tu orientación vocacional';
sectionTitle.fontSize = 18;
sectionTitle.fills = [{ type: 'SOLID', color: COLORS.textPrimary }];

const metricsRow = figma.createFrame();
metricsRow.layoutMode = 'HORIZONTAL';
metricsRow.primaryAxisSizingMode = 'AUTO';
metricsRow.counterAxisSizingMode = 'AUTO';
metricsRow.itemSpacing = 12;
metricsRow.fills = [];
metricsRow.appendChild(metricComp.createInstance());
metricsRow.appendChild(metricComp.createInstance());

const statusCard = figma.createFrame();
statusCard.name = 'Status Card';
statusCard.layoutMode = 'VERTICAL';
statusCard.primaryAxisSizingMode = 'AUTO';
statusCard.counterAxisSizingMode = 'FIXED';
statusCard.resize(358, 140);
statusCard.paddingLeft = 16;
statusCard.paddingRight = 16;
statusCard.paddingTop = 16;
statusCard.paddingBottom = 16;
statusCard.itemSpacing = 8;
statusCard.cornerRadius = 12;
statusCard.fills = [{ type: 'SOLID', color: COLORS.surface }];

const statusLabel = figma.createText();
statusLabel.fontName = { family: 'Inter', style: 'Regular' };
statusLabel.characters = 'Test vocacional';
statusLabel.fontSize = 14;
statusLabel.fills = [{ type: 'SOLID', color: COLORS.textSecondary }];

const statusValue = figma.createText();
statusValue.fontName = { family: 'Inter', style: 'Bold' };
statusValue.characters = 'En progreso — 45%';
statusValue.fontSize = 20;
statusValue.fills = [{ type: 'SOLID', color: COLORS.textPrimary }];

const progress = figma.createRectangle();
progress.resize(326, 8);
progress.cornerRadius = 4;
progress.fills = [{ type: 'SOLID', color: { r: 0.9, g: 0.92, b: 0.95 } }];

statusCard.appendChild(statusLabel);
statusCard.appendChild(statusValue);
statusCard.appendChild(progress);

const actions = figma.createFrame();
actions.layoutMode = 'VERTICAL';
actions.primaryAxisSizingMode = 'AUTO';
actions.counterAxisSizingMode = 'FIXED';
actions.resize(358, 56);
actions.fills = [];
const cta = btnComp.createInstance();
cta.layoutSizingHorizontal = 'FILL';
actions.appendChild(cta);

const disclaimer = figma.createFrame();
disclaimer.layoutMode = 'VERTICAL';
disclaimer.primaryAxisSizingMode = 'AUTO';
disclaimer.counterAxisSizingMode = 'FIXED';
disclaimer.resize(358, 80);
disclaimer.paddingLeft = 12;
disclaimer.paddingRight = 12;
disclaimer.paddingTop = 12;
disclaimer.paddingBottom = 12;
disclaimer.cornerRadius = 8;
disclaimer.fills = [{ type: 'SOLID', color: { ...COLORS.accent, a: 0.15 } }];

const discText = figma.createText();
discText.fontName = { family: 'Inter', style: 'Regular' };
discText.characters =
  'Este resultado es orientativo y no reemplaza la orientación profesional.';
discText.fontSize = 12;
discText.fills = [{ type: 'SOLID', color: COLORS.textSecondary }];
disclaimer.appendChild(discText);

dashBody.appendChild(sectionTitle);
dashBody.appendChild(metricsRow);
dashBody.appendChild(statusCard);
dashBody.appendChild(actions);
dashBody.appendChild(disclaimer);
dashboard.appendChild(dashBody);
createdScreenIds.push({ name: 'Dashboard / Estudiante', id: dashboard.id });

// --- TEST VOCACIONAL ---
const test = createMobileScreen('Test Vocacional', 860);
test.appendChild(createAppBar('Test vocacional', { showClose: true }));

const testBody = figma.createFrame();
testBody.name = 'Body';
testBody.layoutMode = 'VERTICAL';
testBody.primaryAxisSizingMode = 'FILL';
testBody.counterAxisSizingMode = 'FILL';
testBody.paddingLeft = 16;
testBody.paddingRight = 16;
testBody.paddingTop = 16;
testBody.paddingBottom = 16;
testBody.itemSpacing = 16;
testBody.fills = [];

const progressHeader = figma.createFrame();
progressHeader.layoutMode = 'HORIZONTAL';
progressHeader.primaryAxisSizingMode = 'AUTO';
progressHeader.counterAxisSizingMode = 'AUTO';
progressHeader.primaryAxisAlignItems = 'SPACE_BETWEEN';
progressHeader.fills = [];

const qNum = figma.createText();
qNum.fontName = { family: 'Inter', style: 'Semi Bold' };
qNum.characters = 'Pregunta 12 de 60';
qNum.fontSize = 14;
qNum.fills = [{ type: 'SOLID', color: COLORS.textSecondary }];

const category = figma.createText();
category.fontName = { family: 'Inter', style: 'Regular' };
category.characters = 'Categoría: Investigador (I)';
category.fontSize = 12;
category.fills = [{ type: 'SOLID', color: COLORS.primary }];

progressHeader.appendChild(qNum);
progressHeader.appendChild(category);

const progressBar = figma.createRectangle();
progressBar.resize(358, 6);
progressBar.cornerRadius = 3;
progressBar.fills = [{ type: 'SOLID', color: { r: 0.9, g: 0.92, b: 0.95 } }];

const questionCard = figma.createFrame();
questionCard.layoutMode = 'VERTICAL';
questionCard.primaryAxisSizingMode = 'AUTO';
questionCard.counterAxisSizingMode = 'FIXED';
questionCard.resize(358, 180);
questionCard.paddingLeft = 16;
questionCard.paddingRight = 16;
questionCard.paddingTop = 20;
questionCard.paddingBottom = 20;
questionCard.cornerRadius = 12;
questionCard.fills = [{ type: 'SOLID', color: COLORS.surface }];

const question = figma.createText();
question.fontName = { family: 'Inter', style: 'Semi Bold' };
question.characters = '¿Te gustaría investigar sobre nuevos tratamientos médicos?';
question.fontSize = 18;
question.fills = [{ type: 'SOLID', color: COLORS.textPrimary }];
question.resize(326, 120);
questionCard.appendChild(question);

const scaleTitle = figma.createText();
scaleTitle.fontName = { family: 'Inter', style: 'Regular' };
scaleTitle.characters =
  'Selecciona tu respuesta (1 = No me gusta nada, 5 = Me gusta mucho)';
scaleTitle.fontSize = 12;
scaleTitle.fills = [{ type: 'SOLID', color: COLORS.textSecondary }];
scaleTitle.resize(358, 32);

const scaleRow = figma.createFrame();
scaleRow.layoutMode = 'HORIZONTAL';
scaleRow.primaryAxisSizingMode = 'AUTO';
scaleRow.counterAxisSizingMode = 'AUTO';
scaleRow.itemSpacing = 8;
scaleRow.fills = [];

for (let i = 1; i <= 5; i++) {
  const opt = figma.createFrame();
  opt.layoutMode = 'VERTICAL';
  opt.primaryAxisSizingMode = 'AUTO';
  opt.counterAxisSizingMode = 'AUTO';
  opt.paddingLeft = 12;
  opt.paddingRight = 12;
  opt.paddingTop = 12;
  opt.paddingBottom = 12;
  opt.cornerRadius = 8;
  opt.fills = [{ type: 'SOLID', color: i === 4 ? COLORS.primary : COLORS.surface }];
  opt.strokes = [{ type: 'SOLID', color: COLORS.border }];
  opt.strokeWeight = 1;
  const num = figma.createText();
  num.fontName = { family: 'Inter', style: 'Bold' };
  num.characters = String(i);
  num.fontSize = 18;
  num.fills = [
    { type: 'SOLID', color: i === 4 ? COLORS.white : COLORS.textPrimary },
  ];
  opt.appendChild(num);
  scaleRow.appendChild(opt);
}

const navRow = figma.createFrame();
navRow.layoutMode = 'HORIZONTAL';
navRow.primaryAxisSizingMode = 'AUTO';
navRow.counterAxisSizingMode = 'FIXED';
navRow.resize(358, 48);
navRow.primaryAxisAlignItems = 'SPACE_BETWEEN';
navRow.fills = [];

const prev = figma.createText();
prev.fontName = { family: 'Inter', style: 'Regular' };
prev.characters = 'Anterior';
prev.fontSize = 14;
prev.fills = [{ type: 'SOLID', color: COLORS.textSecondary }];

const next = figma.createFrame();
next.layoutMode = 'HORIZONTAL';
next.primaryAxisSizingMode = 'AUTO';
next.counterAxisSizingMode = 'AUTO';
next.paddingLeft = 20;
next.paddingRight = 20;
next.paddingTop = 12;
next.paddingBottom = 12;
next.cornerRadius = 8;
next.fills = [{ type: 'SOLID', color: COLORS.primary }];

const nextText = figma.createText();
nextText.fontName = { family: 'Inter', style: 'Semi Bold' };
nextText.characters = 'Siguiente';
nextText.fontSize = 14;
nextText.fills = [{ type: 'SOLID', color: COLORS.white }];
next.appendChild(nextText);

navRow.appendChild(prev);
navRow.appendChild(next);

testBody.appendChild(progressHeader);
testBody.appendChild(progressBar);
testBody.appendChild(questionCard);
testBody.appendChild(scaleTitle);
testBody.appendChild(scaleRow);
testBody.appendChild(navRow);
test.appendChild(testBody);
createdScreenIds.push({ name: 'Test Vocacional', id: test.id });

return {
  createdScreenIds,
  fileUrl: 'https://www.figma.com/design/kZ0uYN2ZYLFcBjNBGhZEU3',
  screenUrls: createdScreenIds.map((s) => ({
    name: s.name,
    url: `https://www.figma.com/design/kZ0uYN2ZYLFcBjNBGhZEU3?node-id=${s.id.replace(':', '-')}`,
  })),
};

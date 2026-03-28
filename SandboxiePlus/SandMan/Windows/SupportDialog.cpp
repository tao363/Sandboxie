#include "stdafx.h"
#include "SupportDialog.h"
#include "SandMan.h"
#include "../MiscHelpers/Common/Common.h"
#include "SettingsWindow.h"
#include <Windows.h>
#include "OnlineUpdater.h"

bool CSupportDialog::m_ReminderShown = false;

QDateTime CSupportDialog::GetSbieInstallationDate()
{
	time_t InstalDate = 0;
	theAPI->GetSecureParam("InstallationDate", &InstalDate, sizeof(InstalDate));

	time_t CurrentDate = QDateTime::currentDateTimeUtc().toSecsSinceEpoch();
	if (InstalDate == 0 || InstalDate > CurrentDate) {
		InstalDate = CurrentDate;
		theAPI->SetSecureParam("InstallationDate", &InstalDate, sizeof(InstalDate));
	}

	return QDateTime::fromSecsSinceEpoch(InstalDate);
}

bool CSupportDialog::IsBusinessUse()
{
	return false;
}

bool CSupportDialog::CheckSupport(bool bOnRun)
{
	return false;
}

bool CSupportDialog::ShowDialog(bool NoGo, int Wait)
{
	return true;
}

CSupportDialog::CSupportDialog(const QString& Message, bool NoGo, int Wait, QWidget *parent)
	: QDialog(parent)
{
	Qt::WindowFlags flags = windowFlags();
	flags |= Qt::CustomizeWindowHint;
	//flags &= ~Qt::WindowContextHelpButtonHint;
	//flags &= ~Qt::WindowSystemMenuHint;
	//flags &= ~Qt::WindowMinMaxButtonsHint;
	//flags |= Qt::WindowMinimizeButtonHint;
	//flags &= ~Qt::WindowCloseButtonHint;
	flags &= ~Qt::WindowContextHelpButtonHint;
	//flags &= ~Qt::WindowSystemMenuHint;
	setWindowFlags(flags);

	//setWindowState(Qt::WindowActive);
	SetForegroundWindow((HWND)QWidget::winId());

	this->setWindowFlag(Qt::WindowStaysOnTopHint, theGUI->IsAlwaysOnTop());

	this->setWindowTitle(tr("Sandboxie-Plus - Support Reminder"));

	this->resize(420, 300);
	QVBoxLayout* verticalLayout = new QVBoxLayout(this);
	QGridLayout* gridLayout = new QGridLayout();

	QHBoxLayout* horizontalLayout = new QHBoxLayout();
	m_Buttons[0] = new QPushButton(this);
	horizontalLayout->addWidget(m_Buttons[0]);
	m_Buttons[1] = new QPushButton(this);
	horizontalLayout->addWidget(m_Buttons[1]);
	m_Buttons[2] = new QPushButton(this);
	horizontalLayout->addWidget(m_Buttons[2]);
	gridLayout->addLayout(horizontalLayout, 2, 0, 1, 1);

	QLabel* label = new QLabel(this);
	QSizePolicy sizePolicy(QSizePolicy::Ignored, QSizePolicy::Expanding);
	sizePolicy.setHorizontalStretch(0);
	sizePolicy.setVerticalStretch(0);
	sizePolicy.setHeightForWidth(label->sizePolicy().hasHeightForWidth());
	label->setSizePolicy(sizePolicy);
	label->setAlignment(Qt::AlignCenter);
	label->setWordWrap(true);
	label->setText(Message);
	connect(label, SIGNAL(linkActivated(const QString&)), theGUI, SLOT(OpenUrl(const QString&)));
	gridLayout->addWidget(label, 1, 0, 1, 1);

	QLabel* logo = new QLabel(this);
	logo->setFrameShape(QFrame::StyledPanel);
	logo->setFrameShadow(QFrame::Plain);
	//QPalette back = logo->palette();
	//SetPaleteTexture(back, QPalette::Window, QImage(":/Assets/sandboxie-back.png"));
	//logo->setPalette(back);
	//logo->setAutoFillBackground(true);
	logo->setStyleSheet("background-image: url(:/Assets/sandboxie-back.png);");
	logo->setPixmap(QPixmap::fromImage(QImage(":/Assets/sandboxie-logo.png")));
	logo->setAlignment(Qt::AlignCenter);
	gridLayout->addWidget(logo, 0, 0, 1, 1);

	verticalLayout->addLayout(gridLayout);


	for (int s = rand() % 3,  i = 0; i < 3; i++)
	{
		QPushButton* pButton = m_Buttons[(s + i) % 3];
		pButton->setAutoDefault(false);
		//pButton->setEnabled(false);
		pButton->setProperty("Action", (i == 1 && NoGo) ? 3 : i);
		connect(pButton, SIGNAL(clicked(bool)), this, SLOT(OnButton()));
	}

	m_CountDown = NoGo ? 0 : Wait;

	UpdateButtons();

	m_uTimerID = startTimer(1000);
}

CSupportDialog::~CSupportDialog()
{
	killTimer(m_uTimerID);
}

void CSupportDialog::timerEvent(QTimerEvent* pEvent)
{
	if (pEvent->timerId() != m_uTimerID)
		return;

	if (m_CountDown >= 0)
		UpdateButtons();
}

void CSupportDialog::UpdateButtons()
{
	if (m_CountDown-- > 0) 
		m_Buttons[1]->setText(tr("%1").arg(m_CountDown + 1));
	else 
	{
		for (int i = 0; i < 3; i++) {
			QPushButton* pButton = m_Buttons[i];
			//pButton->setEnabled(true);
			switch (pButton->property("Action").toInt()) {
			case 0:	pButton->setText(tr("Quit")); break;
			case 1:	pButton->setText(tr("Continue")); break;
			case 2: pButton->setText(tr("Get Certificate")); break;
			case 3: pButton->setText(tr("Enter Certificate")); break;
			}
		}
	}
}

void CSupportDialog::OnButton()
{
	int Action = ((QPushButton*)sender())->property("Action").toInt();

	if (Action == 1)
		accept();
	else
		reject();
}

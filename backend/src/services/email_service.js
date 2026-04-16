/**
 * Email Service using SendGrid or SMTP
 * Handles all outgoing email communications
 */
const nodemailer = require('nodemailer');

class EmailService {
  constructor() {
    // Configure email transport (Update with your SMTP provider)
    if (process.env.EMAIL_SERVICE === 'sendgrid') {
      this.transporter = this._createSendGridTransport();
    } else {
      // Fallback to SMTP (Gmail, or custom SMTP)
      this.transporter = this._createSMTPTransport();
    }
  }

  /**
   * Create SendGrid Transport
   */
  _createSendGridTransport() {
    if (!process.env.SENDGRID_API_KEY) {
      console.warn('⚠️  SENDGRID_API_KEY not configured');
      return null;
    }

    const sgTransport = require('nodemailer-sendgrid-transport');
    return nodemailer.createTransport(
      sgTransport({
        auth: {
          api_key: process.env.SENDGRID_API_KEY,
        },
      })
    );
  }

  /**
   * Create SMTP Transport
   */
  _createSMTPTransport() {
    return nodemailer.createTransport({
      service: process.env.SMTP_SERVICE || 'gmail',
      host: process.env.SMTP_HOST,
      port: process.env.SMTP_PORT || 587,
      secure: process.env.SMTP_SECURE === 'true',
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASSWORD,
      },
    });
  }

  /**
   * Send Email
   */
  async sendEmail(to, subject, htmlContent, textContent = '') {
    if (!this.transporter) {
      console.error('❌ Email service not configured');
      return false;
    }

    try {
      const mailOptions = {
        from: process.env.EMAIL_FROM || 'noreply@impactknowledge.app',
        to,
        subject,
        html: htmlContent,
        text: textContent || htmlContent.replace(/<[^>]*>/g, ''),
      };

      const info = await this.transporter.sendMail(mailOptions);
      console.log(`✅ Email sent to ${to}: ${info.messageId}`);
      return true;
    } catch (error) {
      console.error(`❌ Failed to send email to ${to}: ${error.message}`);
      return false;
    }
  }

  /**
   * Welcome Email
   */
  async sendWelcomeEmail(userEmail, userName) {
    const subject = '🎉 Welcome to ImpactKnowledge!';
    const htmlContent = `
      <h2>Welcome to ImpactKnowledge, ${userName}!</h2>
      <p>We're excited to have you join our learning community.</p>
      <p>Here's what you can do next:</p>
      <ul>
        <li>Complete your profile</li>
        <li>Explore available courses</li>
        <li>Set your learning goals</li>
        <li>Connect with other learners</li>
      </ul>
      <p><a href="${process.env.APP_URL}/dashboard">Go to Dashboard</a></p>
      <p>Happy learning!</p>
    `;

    return this.sendEmail(userEmail, subject, htmlContent);
  }

  /**
   * Achievement Unlock Email
   */
  async sendAchievementEmail(userEmail, userName, achievementName, achievementIcon) {
    const subject = `🏆 Achievement Unlocked: ${achievementName}`;
    const htmlContent = `
      <h2>Congratulations ${userName}! 🎉</h2>
      <p>You've unlocked the achievement: <strong>${achievementName}</strong></p>
      <p>Keep up the great work!</p>
      <p><a href="${process.env.APP_URL}/achievements">View Your Achievements</a></p>
    `;

    return this.sendEmail(userEmail, subject, htmlContent);
  }

  /**
   * Course Completion Email
   */
  async sendCourseCompletionEmail(userEmail, userName, courseName, certificateUrl) {
    const subject = `✅ Course Completed: ${courseName}`;
    const htmlContent = `
      <h2>You've Completed ${courseName}! 🎓</h2>
      <p>Congratulations ${userName}!</p>
      <p>You have successfully completed ${courseName}.</p>
      <p><a href="${certificateUrl}">Download Your Certificate</a></p>
      <p><a href="${process.env.APP_URL}/courses">Explore More Courses</a></p>
    `;

    return this.sendEmail(userEmail, subject, htmlContent);
  }

  /**
   * Quiz Score Email
   */
  async sendQuizScoreEmail(userEmail, userName, quizName, score, maxScore) {
    const percentage = Math.round((score / maxScore) * 100);
    const subject = `📊 Quiz Results: ${quizName}`;
    const htmlContent = `
      <h2>Quiz Results for ${quizName}</h2>
      <p>Hi ${userName},</p>
      <p>Your score: <strong>${score}/${maxScore} (${percentage}%)</strong></p>
      <p>${percentage >= 70 ? '✅ Great job! You passed!' : '⚠️  Keep practicing! You can retake the quiz.'}</p>
      <p><a href="${process.env.APP_URL}/quizzes">Retake Quiz</a></p>
    `;

    return this.sendEmail(userEmail, subject, htmlContent);
  }

  /**
   * Password Reset Email
   */
  async sendPasswordResetEmail(userEmail, resetToken, userName) {
    const resetLink = `${process.env.APP_URL}/reset-password?token=${resetToken}`;
    const subject = '🔐 Reset Your ImpactKnowledge Password';
    const htmlContent = `
      <h2>Password Reset Request</h2>
      <p>Hi ${userName},</p>
      <p>We received a request to reset your ImpactKnowledge password.</p>
      <p><a href="${resetLink}" style="padding: 12px 24px; background-color: #007bff; color: white; text-decoration: none; border-radius: 4px;">
        Reset Password
      </a></p>
      <p>This link expires in 24 hours.</p>
      <p>If you didn't request this, you can ignore this email.</p>
    `;

    return this.sendEmail(userEmail, subject, htmlContent);
  }

  /**
   * Event Reminder Email
   */
  async sendEventReminderEmail(userEmail, userName, eventName, eventDate, eventTime) {
    const subject = `📅 Reminder: ${eventName} is coming up!`;
    const htmlContent = `
      <h2>Event Reminder</h2>
      <p>Hi ${userName},</p>
      <p>This is a reminder that <strong>${eventName}</strong> is happening:</p>
      <p><strong>Date:</strong> ${eventDate}</p>
      <p><strong>Time:</strong> ${eventTime}</p>
      <p><a href="${process.env.APP_URL}/events">View Event Details</a></p>
    `;

    return this.sendEmail(userEmail, subject, htmlContent);
  }

  /**
   * Admin Alert Email
   */
  async sendAdminAlertEmail(adminEmail, alertType, alertMessage, alertData) {
    const subject = `⚠️  Admin Alert: ${alertType}`;
    const htmlContent = `
      <h2>${alertType}</h2>
      <p>${alertMessage}</p>
      <pre>${JSON.stringify(alertData, null, 2)}</pre>
      <p><a href="${process.env.APP_URL}/admin/alerts">View Alert Details</a></p>
    `;

    return this.sendEmail(adminEmail, subject, htmlContent);
  }

  /**
   * Weekly Summary Email
   */
  async sendWeeklySummaryEmail(userEmail, userName, summaryData) {
    const subject = '📊 Your Weekly Learning Summary';
    const htmlContent = `
      <h2>Your Weekly Summary</h2>
      <p>Hi ${userName},</p>
      <p>Here's what you accomplished this week:</p>
      <ul>
        <li>Lessons completed: ${summaryData.lessonsCompleted}</li>
        <li>Time spent learning: ${summaryData.hoursSpent}h</li>
        <li>Achievements unlocked: ${summaryData.achievementsUnlocked}</li>
        <li>Current streak: ${summaryData.streakDays} days 🔥</li>
      </ul>
      <p>Keep it up!</p>
      <p><a href="${process.env.APP_URL}/dashboard">View Dashboard</a></p>
    `;

    return this.sendEmail(userEmail, subject, htmlContent);
  }
}

module.exports = new EmailService();

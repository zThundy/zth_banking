import { writable, type Writable } from "svelte/store";

export interface Notification {
  id: number;
  message: string;
  title: string;
  icon: string;
}

export const notifications = writable<Notification[]>([]);
let notificationId = 0;

export function Notify(message: string, title: string, icon: string) {
  notificationId += 1;
  const newNotification: Notification = {
    id: notificationId,
    message,
    title,
    icon,
  };
  notifications.update((n) => [...n, newNotification]);
  setTimeout(() => {
    notifications.update((n) =>
      n.filter((notification) => notification.id !== newNotification.id)
    );
  }, 2000);
}

export const showATM = writable(false);
export const atmCurrency = writable("USD");

export const showOverview = writable(true);
export const showHistory = writable(false);
export const showWithdraw = writable(false);
export const showDeposit = writable(false);
export const showStats = writable(false);
export const showCreditCard = writable(false);
export const showCompanies = writable(false);

export const currentCash = writable(0);
export const currentMexCash = writable(0);
export const bankBalance = writable(0);
export const bankBalanceMex = writable(0);
export const conversionRate = writable(0.0);

export const companyData = writable({
  name: "Peer Inc.",
  balance: 123456,
  balanceMex: 123456,
  currency: "USD",
  users: [
    {
      id: "1",
      name: "John Doe",
      isboss: true,
    },
    // {
    //   id: "2",
    //   name: "Jane Doe",
    //   isboss: false,
    // },
    // {
    //   id: "3",
    //   name: "Alice Doe",
    //   isboss: false,
    // },
    // {
    //   id: "4",
    //   name: "John Doe",
    //   isboss: true,
    // },
    // {
    //   id: "5",
    //   name: "Jane Doe",
    //   isboss: false,
    // },
    // {
    //   id: "6",
    //   name: "Alice Doe",
    //   isboss: false,
    // }
  ]
});

export const creditCardData = writable({
  name: "Jhon Doe",
  number: "0000000000000000",
  cvv: "521",
  pin: "12345",
  expiration: "",
});

export const Locales = writable({
  open: "Open",
  atm: "ATM",
  cash: "Cash",
  bank_balance: "Bank Balance",
  deposit_amount: "Deposit Amount",
  withdraw_amount: "Withdraw Amount",
  submit: "Submit",
  close: "Close",
  overview: "Overview",
  history: "History",
  withdraw: "Withdraw",
  deposit: "Deposit",
  stats: "Stats",
  total: "Total",
  search_transactions: "Search transactions...",
  amount: "Amount",
  date: "Date",
  payment_completed: "Payment Completed",
  delete_all_transactions: "Delete All Transactions",
  are_you_sure: "Are you sure?",
  delete_confirmation: "Are you sure you want to delete all your transactions? (Only do this if the menu lags!)",
  cancel: "Cancel",
  confirm: "Confirm",
  history_empty: "Your history is empty",
  all_history_deleted: "You have deleted all your history",
  error: "Error",
  success: "Success",
  new_cash: "New Cash",
  withdraw_success: "Withdrawal Successful",
  withdraw_error: "Your bank account does not have enough funds",
  withdraw_button: "WITHDRAW",
  new_bank: "New Bank Balance",
  current_cash: "Current Cash",
  deposit_success: "Deposit Successful",
  deposit_error: "You do not have enough cash",
  deposit_button: "DEPOSIT",
  total_balance: "Total Bank Balance",
  quick_actions: "Quick Actions",
  weekly_summary: "Weekly Summary",
  income: "Income",
  expenses: "Expenses",
  report: "Report",
  latest_transactions: "Latest Transactions",
  see_all: "SEE ALL",
  no_cash_on_you: "You have no cash on you",
  no_money_on_account: "Your account is empty",
  statistics_reports: "Statistics and Reports",
  withdrawn: "You have withdrawn",
  deposited: "You have deposited",
  no_transactions: "No recent transactions",
  transactions_trend: "Transactions Trend",
  total_transactions: "Total Transactions",
  stats_history_positive: "Positive",
  stats_history_negative: "Negative",
  // credit cards
  credit_card: "Credit Card",
  credit_card_description: "Manage your credit card",
  credit_card_number: "Credit Card Number",
  card_requested: "Card Requested",
  card_requested_description: "You have requested a new card",
  card_controls: "Card Controls",
  hide_pin: "Hide PIN",
  show_pin: "Show PIN",
  change_pin: "Change PIN",
  request_card: "Request Card",
  lock_card: "Lock Card",
  unlock_card: "Unlock Card",
  new_pin: "New PIN",
  pin_change_error: "PIN change error",
  pin_change_error_description: "An error occurred while changing the PIN.",
  // companies
  companies: "Companies",
  company_info: "Company Info",
  company_name: "Company Name",
  company_balance: "Company Balance",
  company_actions: "Company Actions",
  company_deposit_description: "You are about to deposit money to this company.",
  company_deposit_input_description: "Please enter the amount you want to deposit:",
  company_withdraw_description: "You are about to withdraw money from this company.",
  company_withdraw_input_description: "Please enter the amount you want to withdraw:",
  company_invalid_amount: "Invalid amount",
  company_invalid_amount_description: "The amount you entered is invalid.",
  company_insufficient_funds: "Insufficient funds",
  company_insufficient_funds_description: "The company does not have enough funds.",
  company_deposit_error: "Deposit error",
  company_deposit_error_description: "An error occurred while depositing money to the company.",
  company_withdraw_error: "Withdrawal error",
  company_withdraw_error_description: "An error occurred while withdrawing money from the company.",
  company_withdraw_success: "Withdrawal successful",
  company_withdraw_success_description: "You have successfully withdrawn money from the company.",
  company_deposit_success: "Deposit successful",
  company_deposit_success_description: "You have successfully deposited money to the company.",
  company_manage_users: "Manage Users",
  company_remove_access: "Remove Access",
  company_remove_access_description: "You have removed access to this company to",
  company_give_access: "Grant Access",
  company_give_access_description: "You have granted access to this company to",
  company_access_error: "Access error",
  company_access_error_description: "An error occurred while managing company access.",
});

export const Transactions: Writable<Array<any>> = writable([
  // {
  //   id: 1,
  //   description: "Payment to John Doe",
  //   type: "bank",
  //   amount: 1000,
  //   date: "2022/08/13",
  //   isIncome: false,
  // },
  // {
  //   id: 2,
  //   description: "Payceck",
  //   type: "bank",
  //   amount: 500,
  //   date: "2022/08/13",
  //   isIncome: true,
  // },
  // {
  //   id: 3,
  //   description: "Payceck",
  //   type: "bank",
  //   amount: 500,
  //   date: "2022/08/13",
  //   isIncome: true,
  // },
  // {
  //   id: 4,
  //   description: "Payceck",
  //   type: "bank",
  //   amount: 500,
  //   date: "2022/08/13",
  //   isIncome: true,
  // },
  // {
  //   id: 5,
  //   description: "Payceck",
  //   type: "bank",
  //   amount: 500,
  //   date: "2022/08/13",
  //   isIncome: true,
  // },
  // {
  //   id: 6,
  //   description: "Payment to John Doe",
  //   type: "bank",
  //   amount: 1000,
  //   date: "2022/08/13",
  //   isIncome: false,
  // },
  // {
  //   id: 7,
  //   description: "Payment to John Doe",
  //   type: "bank",
  //   amount: 1000,
  //   date: "2022/08/13",
  //   isIncome: false,
  // },
  // {
  //   id: 8,
  //   description: "Payment to John Doe",
  //   type: "bank",
  //   amount: 1000,
  //   date: "2022/08/13",
  //   isIncome: false,
  // },
  // {
  //   id: 9,
  //   description: "Payceck",
  //   type: "bank",
  //   amount: 500,
  //   date: "2022/08/13",
  //   isIncome: true,
  // },
  // {
  //   id: 10,
  //   description: "Payceck",
  //   type: "bank",
  //   amount: 500,
  //   date: "2022/08/13",
  //   isIncome: true,
  // },
  // {
  //   id: 11,
  //   description: "Payceck",
  //   type: "bank",
  //   amount: 500,
  //   date: "2022/08/13",
  //   isIncome: true,
  // },
  // {
  //   id: 12,
  //   description: "Payceck",
  //   type: "bank",
  //   amount: 500,
  //   date: "2022/08/13",
  //   isIncome: true,
  // },
  // {
  //   id: 13,
  //   description: "Payceck",
  //   type: "bank",
  //   amount: 500,
  //   date: "2022/08/13",
  //   isIncome: true,
  // },
  // {
  //   id: 14,
  //   description: "Payceck",
  //   type: "bank",
  //   amount: 500,
  //   date: "2022/08/13",
  //   isIncome: true,
  // },
  // {
  //   id: 15,
  //   description: "Payment to John Doe",
  //   type: "bank",
  //   amount: 1000,
  //   date: "2022/08/13",
  //   isIncome: false,
  // },
]);
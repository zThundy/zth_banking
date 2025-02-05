

import { fetchNui } from "../utils/fetchNui";
import {
  bankBalance,
  bankBalanceMex,
  conversionRate,
  currentCash,
  currentMexCash,
  Locales,
} from "./data";

export async function updateBalances() {
  try {
    const response = await fetchNui("fd_banking:client:getMoneyTypes", {});
    if (!response.moneyData || !response.conversionRate) {
      response.moneyData = [
        { name: "bank", amount: bankBalance },
        { name: "cash", amount: currentCash },
        { name: "mexcash", amount: currentMexCash },
      ];
      response.conversionRate = conversionRate;
    }
    const bank = response.moneyData.find(
      (item: { name: string }) => item.name === "bank",
    );
    const cash = response.moneyData.find(
      (item: { name: string }) => item.name === "cash",
    );
    const mexcash = response.moneyData.find(
      (item: { name: string }) => item.name === "mexcash",
    );
    if (bank) {
      bankBalance.set(bank.amount);
      bankBalanceMex.set(bank.amount * response.conversionRate);
    }
    if (cash) {
      currentCash.set(cash.amount);
    }
    if (mexcash) {
      currentMexCash.set(mexcash.amount);
    }
    conversionRate.set(response.conversionRate);
  } catch (error) {
    console.error(error);
  }
}

export function floorToTwoDecimals(value: number): any {
  // return Math.ceil(value * 100) / 100;
  return Math.floor(value);
}

export function ceilToTwoDecimals(value: number): any {
  // return Math.floor(value * 100) / 100;
  return Math.ceil(value);
}

export function getLocales() {
  fetchNui("fd_banking:client:getLocales", {})
    .then((response) => {
      Locales.set(response);
    })
    .catch((error) => {
      console.error(error);
    });
}
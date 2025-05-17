const systemPrompt = `
You are a Malaysian tax consultant AI. Classify expenses based on these tax relief categories:

1. Individual and dependent relatives
2. Expenses for parents (medical, dental, carer)
3. Basic supporting equipment for disabled
4. Disabled individual
5. Education fees (law, accounting, technical, etc)
6. Medical expenses (serious disease, fertility, vaccination, dental)
7. Medical exams & COVID tests
8. Child intellectual disability expenses
9. Lifestyle – books, gadgets, internet, skills
10. Lifestyle – sports equipment, facility, training
11. Breastfeeding equipment
12. Childcare fees
13. SSPN education savings
14. Spouse / alimony
15. Disabled spouse
16. Children
17. Life insurance, EPF
18. Annuity & PRS
19. Education/medical insurance
20. SOCSO
21. EV charging expenses

Return ONLY the category number (1-21) for the expense. If it doesn't qualify, return "Non-claimable".
`;

export const classifyExpense = async ({ merchant, items, amount }) => {
  const prompt = `
Merchant: ${merchant}
Items: ${items}
Amount: RM${amount}

Which tax relief category does this fall under? Return only the category number or "Non-claimable".
`;

  const response = await fetch(process.env.QWEN_API_URL, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.QWEN_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      prompt: systemPrompt + prompt
    })
  });

  const result = await response.json();
  
  // Extract just the category number or "Non-claimable"
  const category = result.text.trim();
  
  // If it's a number between 1-21, return it as a number, otherwise return the string
  const categoryNumber = parseInt(category);
  if (!isNaN(categoryNumber) && categoryNumber >= 1 && categoryNumber <= 21) {
    return categoryNumber;
  }
  
  return category;
};
